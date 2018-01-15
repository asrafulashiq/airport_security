function [R_bin] =  match_template_signal_half(I, loc_something, R_bin, flag, I_rgb)
global debug;
global scale;
global save_features;

obj_num = numel(R_bin.bin_array);
thr = 0.8;

if flag == 1
    flow = estimateFlow(R_bin.optic_flow, I);
    R_bin.flow = flow;
else
    flow = R_bin.flow;
end
%%
r_tall_val = 160;
r_tall_width = floor(220 * scale);
r_tall_bin = create_rect(r_tall_width, 5, r_tall_val);

% create rectangular wide pulse
r_wide_val = 140;
r_wide_width = floor(280 * scale);
r_wide = create_rect(r_wide_width, 5, r_wide_val);

r_tall = r_tall_bin;

if obj_num == 0
    
    % match
    coef_aray = [];
    loc_array = [];
    
    if isempty(loc_something)
        loc_something = [1 size(I,1)/2];
    end
    
    if loc_something(2) > size(I,1)*.6
        loc_something(2) = size(I,1)*.6;
    end
    
    %loc_end = loc_something(2) - length(r_tall) + 1;
    
    if abs(loc_something(2) - loc_something(1)) <= thr * length(r_tall)
        return;
    end
    
    if abs(loc_something(2) - loc_something(1))> thr * length(r_tall) && loc_something(2)-loc_something(1) < length(r_tall)
        r_tall = ones(1, int64(loc_something(2) - loc_something(1)+1) );
        r_tall(1:3) = 0; r_tall(end-2:end) = 0;
        r_tall = r_tall * r_tall_val;
    end
    
    epsilon = 0.05;
    
    limit_std = 30;
    for i = loc_something(1): ( loc_something(2) -  length(r_tall) + 1 )
        I_d = calc_intens(I(:, 1:int32(size(I,2)*0.7)), [ i i+length(r_tall)-1 ]);
        %coef = sum(abs( r_tall - I_d )) / length(r_tall);
        coef = calc_coef_w(r_tall, I_d);
        
        if std(I_d) > limit_std
            continue;
        end
        
        if coef > 60
            continue;
        end
        
        flow_bin_y = flow.Vy(i:i+length(r_tall)-1, 10:size(I,2)/2);
        flow_bin_y1 = flow_bin_y(1:end/2, :);
        flow_bin_y2 = flow_bin_y(end/2:end, :);
        
        if sum(flow_bin_y1(:)) < -1000 || sum(flow_bin_y2(:)) < -2000
            continue;
        end
        
        coef_aray = [ coef_aray coef ];
        loc_array = [loc_array i];
        
    end
    
    if isempty(coef_aray)
        return;
    end
    
    [ min_val , min_index] = min(coef_aray);
    min_loc = loc_array(min_index);
    
    loc_end = min_loc + length(r_tall)-1;
    height = loc_end - min_loc + 1;
    T_ = I( min_loc: min_loc+length(r_tall)-1, : );
    Loc = [  size(I,2)/2  min_loc+length(r_tall)/2-1 ];
    
    %%% draw
    if debug
        plot( min_loc:loc_end, r_tall );
        %disp("min loc :"+min_loc);
        %disp("min value :"+min_val);
    end
    
    
    Bin = struct( ...
        'Area',size(T_,1)*size(T_,2), 'Centroid', Loc', ...
        'BoundingBox', [1 min_loc size(I,2) height ], ...
        'limit', [ min_loc loc_end ] ,...
        'image',I( min_loc : loc_end , : ), ...
        'belongs_to', -1, ...
        'label', -1, ...
        'in_flag', 1, 'r_val', r_tall_val, 'bin_or',"tall", ...
        'state', "empty", 'count', 1, ...
        'std', std(calc_intens(I, [min_loc loc_end]), 1), 'destroy', false ...
        );
    
    R_bin.bin_array{end+1} = Bin;
    
    
    %% save images bounding box for training
    if save_features
        fname = fullfile(R_bin.imname,sprintf('%d_%s.jpg', R_bin.imno, R_bin.file_number));
        imwrite( I_rgb, fname);
        
        R_bin.filenames{end+1} = sprintf('%-20s',fname);
        R_bin.bb{end+1} = Bin.BoundingBox;
        
        R_bin.imno = R_bin.imno + 1;
    end
    
else
    
    loc_something_actual = loc_something;
    
    
    for i = 1:obj_num
        
        r_bin = r_tall_bin;
        
        
        loc_to_match = [];
        
        flow_bin_y = flow.Vy(R_bin.bin_array{i}.limit(1):R_bin.bin_array{i}.limit(2), 10:size(I,2)/2);
        flow_bin_Orientation = flow.Orientation(R_bin.bin_array{i}.limit(1):R_bin.bin_array{i}.limit(2), 10:size(I,2)/2);
        
        epsilon = 0.05;
        flow_bin_Orientation = rad2deg(flow_bin_Orientation);
        flow_index = (flow_bin_y > epsilon) & (flow_bin_Orientation> 70) ...
            & (flow_bin_Orientation < 110);
        mean_vy = mean(flow_bin_y(flow_index));
        mean_theta = mean(flow_bin_Orientation(flow_index));
        
        if debug
            disp('flow value :'); disp(mean_vy);
            disp('theta :'); disp(mean_theta);
            disp('');
        end
        lim = int32(10 * scale);
        lim_b = int32(10 * scale);
        if ~isnan(mean_vy) && ~isnan(mean_theta)
            
            if mean_vy >=0
                lim = int32(20 * mean_vy);
            else
                lim_b = int32(20 * abs(mean_vy));
            end
        end
        
        
        
        if isfield(R_bin.bin_array{i},'bin_or') && R_bin.bin_array{i}.bin_or=="wide"
            r_bin = create_rect(r_wide_width, 5, R_bin.bin_array{i}.r_val);
        end
        
        k = 0;
        while isempty(loc_to_match)
            
            loc_to_match = loc_match(R_bin.bin_array,i,loc_something,lim,lim_b);
            
            if loc_to_match(2) < loc_to_match(1)
                R_bin.bin_array{i} = [];
                continue;
            end
            
            if loc_to_match(2) - loc_to_match(1) < thr * length(r_bin)
                lim_b = lim_b + 5;
                lim = lim + 5;
                loc_to_match = [];
                k = k+1;
            end
            
            if k > 10
                if isfield(R_bin.bin_array{i},'bin_or') && R_bin.bin_array{i}.bin_or=="wide"
                    r_bin = create_rect(r_tall_width, 5, R_bin.bin_array{i}.r_val);
                    R_bin.bin_array{i}.r_val = r_tall_val;
                    R_bin.bin_array{i}.bin_or = "tall";
                    loc_to_match = loc_match(R_bin.bin_array,i,loc_something,lim,lim_b);
                    break;
                    %                 else
                    %                     r_bin = create_rect(60, 5, R_bin.bin_array{i}.r_val);
                    %                     R_bin.bin_array{i}.r_val = 60;
                    %                     R_bin.bin_array{i}.bin_or = "tall";
                    %                     loc_to_match = loc_match(R_bin.bin_array,i,loc_something,lim,lim_b);
                end
                R_bin.bin_array{i}.destroy = true;
                disp('PROBLEM:::::::: Check this out !!!!!!!!!!!!!');
                
            end
            
        end
        
        % match
        coef_aray = [];
        loc_array = [];
        r_val = R_bin.bin_array{i}.r_val;
        
        if isfield(R_bin.bin_array{i},'destroy') && R_bin.bin_array{i}.destroy == true
            continue;
        end
        
        %r_bin = create_rect( loc_to_match(2) - loc_to_match(1)+1, 3, r_val );
        
        if abs(loc_to_match(2) - loc_to_match(1)) >= thr * length(r_bin) && loc_to_match(2)-loc_to_match(1) < length(r_bin)
            r_bin = create_rect( loc_to_match(2) - loc_to_match(1)+1, 3, r_val );
        else
            if isfield(R_bin.bin_array{i},'bin_or') && R_bin.bin_array{i}.bin_or == "wide"
                r_bin = create_rect(r_wide_width, 5, r_val);
            else
                r_bin = create_rect(r_tall_width, 5, r_val);
            end
        end
        
        for j = loc_to_match(1): loc_to_match(2)- length(r_bin) + 1
            % width = R_bin.bin_array{i}.limit(2) - R_bin.bin_array{i}.limit(1)+1;
            I_d = calc_intens(I(:, 1:int32(size(I,2)/2)), [ j j+length(r_bin)-1 ]);
            coef = calc_coef(r_bin, I_d, R_bin.bin_array{i}.std);
            coef_aray = [ coef_aray coef ];
            loc_array = [loc_array j];
        end
        
        if isempty(coef_aray)
            R_bin.bin_array(i).destroy = true;
            %disp('coef array is empty');
            continue;
        end
        
        
        
        [ min_val , min_index] = min(coef_aray);
        min_loc = loc_array(min_index);
        loc_end = min_loc + length(r_bin)-1;
        
        if debug
            %disp('min val :');
            %disp(min_val);
        end
        
        %%% check wide
        if R_bin.bin_array{i}.state=="empty" && R_bin.bin_array{i}.bin_or == "tall" && R_bin.bin_array{i}.count < 150
            
            lim_b = r_wide_width - r_tall_width;
            lim = 50;
            r_wide_val = R_bin.bin_array{i}.r_val ;
            r_wide = create_rect(r_wide_width, 5, r_wide_val);
            
            loc_to_match_w = loc_match(R_bin.bin_array,i,loc_something,lim,lim_b);
            if abs(loc_to_match_w(2) - loc_to_match_w(1))> thr * length(r_wide)
                if loc_to_match_w(2)-loc_to_match_w(1) < length(r_wide)
                    r_wide = create_rect( loc_to_match_w(2) - loc_to_match_w(1)+1, 3, r_val);  %*0.8 );
                    
                end
                
                coef_aray_wide = [];
                loc_array_wide = [];
                for j = loc_to_match_w(1): loc_to_match_w(2)- length(r_wide) + 1
                    % width = R_bin.bin_array{i}.limit(2) - R_bin.bin_array{i}.limit(1)+1;
                    I_d = calc_intens(I(:, 1:int32(size(I,2)/2)), [ j j+length(r_wide)-1 ]);
                    coef = calc_coef(r_wide, I_d, R_bin.bin_array{i}.std);
                    coef_aray_wide = [ coef_aray_wide coef ];
                    loc_array_wide = [loc_array_wide j];
                end
                
                if ~isempty(coef_aray_wide)
                    [ min_val_wide , min_index_wide] = min(coef_aray_wide);
                    if min_val_wide < min_val  %&& abs(min_val_wide-min_val) >= 15
                        min_index = min_index_wide;
                        r_bin = r_wide;
                        
                        min_loc = loc_array_wide(min_index);
                        loc_end = min_loc + length(r_bin)-1;
                        
                        R_bin.bin_array{i}.bin_or = "wide";
                        R_bin.bin_array{i}.r_val = r_wide_val;
                        min_val = min_val_wide;
                        
                    end
                end
            end
        elseif R_bin.bin_array{i}.state=="empty" && R_bin.bin_array{i}.bin_or == "wide" %&& R_bin.bin_array{i}.count < 150
            
            lim_b = 10;
            r_tall_w = create_rect(r_tall_width, 5, r_val); %r_tall_bin;
            
            loc_to_match_w = loc_match(R_bin.bin_array,i,loc_something,lim,lim_b);
            if abs(loc_to_match_w(2) - loc_to_match_w(1))> thr * length(r_tall_w)
                if loc_to_match_w(2)-loc_to_match_w(1) < length(r_tall_w)
                    r_tall_w = create_rect( loc_to_match_w(2) - loc_to_match_w(1)+1, 3, r_val );
                    
                end
                
                coef_aray_tall = [];
                loc_array_tall = [];
                for j = loc_to_match_w(1): loc_to_match_w(2)- length(r_tall_w) + 1
                    % width = R_bin.bin_array{i}.limit(2) - R_bin.bin_array{i}.limit(1)+1;
                    I_d = calc_intens(I(:, 1:int32(size(I,2)/2)), [ j j+length(r_tall_w)-1 ]);
                    coef = calc_coef(r_tall_w, I_d, R_bin.bin_array{i}.std);
                    coef_aray_tall = [ coef_aray_tall coef ];
                    loc_array_tall = [loc_array_tall j];
                end
                
                if ~isempty(coef_aray_tall)
                    [ min_val_t , min_index_t] = min(coef_aray_tall);
                    if min_val_t < min_val && abs(min_val_t-min_val) >= 10
                        min_index = min_index_t;
                        r_bin = r_tall_w;
                        
                        min_loc = loc_array_tall(min_index);
                        loc_end = min_loc + length(r_tall_w)-1;
                        
                        R_bin.bin_array{i}.bin_or = "tall";
                        R_bin.bin_array{i}.r_val = r_tall_val;
                        min_val = min_val_t;
                        
                    end
                end
            end
            
            
        end
        
        
        
        %% state calculation
        
        if min_val > 20 && R_bin.bin_array{i}.state ~= "unspec"
            R_bin.bin_array{i}.state = "unspec";
        end
        
        if R_bin.bin_array{i}.state=="unspec"
            
            if ~isfield(R_bin.bin_array{i}, 'recent_unspec')
                R_bin.bin_array{i}.recent_unspec = [];
                R_bin.bin_array{i}.recent_unspec(end+1) = min_val;
            else
                %R_bin.bin_array{i}.recent_unspec
                R_bin.bin_array{i}.recent_unspec( end+1 ) = min_val;
                if length(R_bin.bin_array{i}.recent_unspec) > 5
                    std_unspec = std(R_bin.bin_array{i}.recent_unspec(end-4:end), 1);
                    if std_unspec < 15
                        % change state
                        if mean2( I(min_loc:loc_end, :)) > 110
                            % empty state
                            R_bin.bin_array{i}.state = "empty";
                            R_bin.bin_array{i}.r_val = mean2( I(min_loc:loc_end, 1:end/2));
                        else
                            R_bin.bin_array{i}.state = "fill";
                            R_bin.bin_array{i}.r_val = mean2( I(min_loc:loc_end, 1:end/2));
                            
                        end
                        R_bin.bin_array{i} = rmfield(R_bin.bin_array{i}, 'recent_unspec');
                    end
                end
            end
        end
        
        
        height = loc_end - min_loc + 1;
        T_ = I( min_loc: min_loc+length(r_bin)-1, : );
        Loc = [  size(I,2)/2  min_loc+length(r_bin)/2-1 ];
        
        %%% draw
        if debug
            plot( min_loc:loc_end, r_bin,  'r--', 'LineWidth', 2 );
            %disp("min loc :"+min_loc);
            %disp("min value :"+min_val);
        end
        
        R_bin.bin_array{i}.Area=size(T_,1)*size(T_,2);
        if isfield(R_bin.bin_array{i}, 'Centroid')
            R_bin.bin_array{i}.p_Centroid = R_bin.bin_array{i}.Centroid;
        end
        R_bin.bin_array{i}.Centroid =  Loc';
        R_bin.bin_array{i}.BoundingBox = [1 min_loc size(I,2) height ];
        R_bin.bin_array{i}.limit= [ min_loc loc_end ];
        if R_bin.bin_array{i}.state=="empty" && isfield(R_bin.bin_array{i}, 'image')
            R_bin.bin_array{i}.p_img = R_bin.bin_array{i}.image;
        end
        %R_bin.bin_array{i}.t_img =  I( min_loc: min_loc+r_tall_width-1, : );
        R_bin.bin_array{i}.image = I( min_loc : loc_end , : );
        R_bin.bin_array{i}.std =  std( calc_intens(I(:, 1:int32(size(I,2)/2)), [min_loc loc_end]) ,1);
        R_bin.bin_array{i}.count = R_bin.bin_array{i}.count + 1;
        loc_something(2) = min_loc;
        
        
        
        %% save image bounding box for training
        if save_features
            fname = fullfile(R_bin.imname,sprintf('%d_%s.jpg', R_bin.imno, R_bin.file_number));
            imwrite( I_rgb, fname);
            R_bin.filenames{end+1} =  sprintf('%-20s',fname);
            R_bin.bb{end+1} = R_bin.bin_array{i}.BoundingBox;
            R_bin.imno = R_bin.imno + 1;
        end
    end
    
    % search lowest y
    min_ = inf;
    for i = 1:size(R_bin.bin_array,2)
        if R_bin.bin_array{i}.limit(1) < min_
            min_ = R_bin.bin_array{i}.BoundingBox(2);
        end
    end
    
    if isinf(min_)
        error('minimum is infinite');
    end
    
    loc_2 = min_;
    if loc_2 >= loc_something(1) + r_tall_width * thr
        
        bins = match_template_signal_half_init( I, [loc_something(1) loc_2], R_bin, 0, I_rgb);
        if ~isempty(bins)
            R_bin.bin_array = {R_bin.bin_array{:} bins{:}};
        end
    end
    
    %%% also search below of bin
    if numel(R_bin.bin_array) >= 1
        
        strt_m = R_bin.bin_array{end}.BoundingBox(2) + R_bin.bin_array{end}.BoundingBox(4) - 1;
        end_m = -1;
        
        if numel(R_bin.bin_array) >= 2
            end_m = R_bin.bin_array{end-1}.BoundingBox(2);
        else
            end_m = loc_something_actual(2);
        end
        bins = [];
        if end_m >= strt_m + r_tall_width * thr
            bins = match_template_signal_half_init( I, [strt_m end_m], R_bin, 0, I_rgb );
        end
        
        if ~isempty(bins)
            %R_bin.bin_array = {R_bin.bin_array{:} bins{:}};
            if numel(R_bin.bin_array) > 1
                R_bin.bin_array = { R_bin.bin_array{1:end-1} bins{:} R_bin.bin_array{end} };
            else
                R_bin.bin_array = { bins{:} R_bin.bin_array{:}};
            end
        end
        
    end
end

end
