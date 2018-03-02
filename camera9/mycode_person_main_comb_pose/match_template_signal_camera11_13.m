function [bin_array, R_belt] =  match_template_signal_camera11_13(I, bin_array, loc_something, R_belt, R_c9, flag)
global debug;
global scale;
global associate;

obj_num = size(bin_array,2);
thr = 0.9;
if flag == 1
    flow = estimateFlow(R_belt.optic_flow, I);
    R_belt.flow = flow;
else
   flow = R_belt.flow; 
end
%%
r_tall_val = 120;
r_tall_width = floor(190 * scale);
r_tall_bin = create_rect(r_tall_width, 5, r_tall_val);

% create rectangular wide pulse
r_wide_val = 110;
r_wide_width = floor(240 * scale);
r_wide = create_rect(r_wide_width, 5, r_wide_val);

r_tall = r_tall_bin;

if obj_num == 0
    
    % match
    coef_aray = [];
    loc_array = [];
    
    bin_or = "tall";
    
    r_width = r_tall_width;
    
    if isempty(loc_something)
        loc_something = [1 size(I,1)/2];
    end
    
    if loc_something(2) > size(I,1)*.4
        loc_something(2) = size(I,1)*.4;
    end
    st = 0; % standard deviation
    %loc_end = loc_something(2) - length(r_tall) + 1;
    r_val = r_tall_val;
    if associate
       intended_label = R_belt.label;
      
       intended_bin = [];     
       % find associated previous bin
       for counter = 1:numel(R_c9.bin_seq)
            if R_c9.bin_seq{counter}.label == intended_label
                intended_bin = R_c9.bin_seq{counter};
                break;
            end
       end
       if ~isempty(intended_bin)
          r_val = intended_bin.r_val ;
          if r_val > 120
             r_val = r_val * 0.6; 
          elseif r_val > 100
              r_val = r_val * 0.8;
          elseif r_val > 70
              r_val = r_val * 0.8;
          end
          st = intended_bin.std;
          if intended_bin.bin_or == "wide"
             r_width = r_wide_width; 
             bin_or = "wide";
          end
          
          intended_bin
          
       end
    else
        r_val = r_tall_val;      
    end
    
    if abs(loc_something(2) - loc_something(1)) <= thr * r_width
        return;
    end
    
    if abs(loc_something(2) - loc_something(1)) > thr * r_width && loc_something(2)-loc_something(1) < r_width
        r_ = ones(1, int64(loc_something(2) - loc_something(1)+1) );
        r_(1:3) = 0; r_(end-2:end) = 0;
        r_ = r_ * r_val;
    else
       r_ = create_rect(r_width, 5, r_val);
    end
    
    
    for i = loc_something(1): ( loc_something(2) -  length(r_) + 1 )
        I_d = calc_intens(I(:, 1:int32(size(I,2)*0.7)), [ i i+length(r_)-1 ]);
        %coef = sum(abs( r_tall - I_d )) / length(r_tall);
        coef = calc_coef_c11(r_, I_d, st);
        
        if coef > 36
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
    
    loc_end = min_loc + length(r_)-1;
    height = loc_end - min_loc + 1;
    T_ = I( min_loc: min_loc+length(r_)-1, : );
    Loc = [  size(I,2)/2  min_loc+length(r_)/2-1 ];
    
    %%% draw
    if debug
        plot( min_loc:loc_end, r_ );
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
        'in_flag', 1, 'r_val', r_val, 'bin_or',bin_or, ...
        'state', "empty", 'count', 1, ...
        'std', std( calc_intens(I, [min_loc loc_end]) ,1), ...
        'match', "unspec", 'destroy', false);
    
    bin_array{end+1} = Bin;
   
else
    
    %loc_something = [ 1  size(I,1) ];
    
    for i = 1:obj_num 
        
        r_bin = r_tall_bin;
      
       
        loc_to_match = [];
        
        flow_bin_y = flow.Vy(bin_array{i}.limit(1):bin_array{i}.limit(2), 10:size(I,2)/2);
        flow_bin_Orientation = flow.Orientation(bin_array{i}.limit(1):bin_array{i}.limit(2), 10:size(I,2)/2);

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
        
        
        if isfield(bin_array{i},'bin_or') && bin_array{i}.bin_or=="wide"
            r_bin = create_rect(r_wide_width, 5, bin_array{i}.r_val);
        end
        
        k = 0;
        while isempty(loc_to_match)
            
            loc_to_match = loc_match(bin_array,i,loc_something,lim,lim_b);
            
            if loc_to_match(2) < loc_to_match(1)
                bin_array{i} = [];
                continue;
            end
            
            if loc_to_match(2) - loc_to_match(1) < thr * length(r_bin)
                lim_b = lim_b + 5;
                lim = lim + 5;
                loc_to_match = [];
                k = k+1;
            end
            
            if k > 10
                if isfield(bin_array{i},'bin_or') && bin_array{i}.bin_or=="wide"
                    r_bin = create_rect(r_tall_width, 5, bin_array{i}.r_val);
                    bin_array{i}.r_val = r_tall_val;
                    bin_array{i}.bin_or = "tall";
                    loc_to_match = loc_match(bin_array,i,loc_something,lim,lim_b);
                    break;
%                 else
%                     r_bin = create_rect(60, 5, bin_array{i}.r_val);
%                     bin_array{i}.r_val = 60;
%                     bin_array{i}.bin_or = "tall";
%                     loc_to_match = loc_match(bin_array,i,loc_something,lim,lim_b);
                end
                bin_array{i}.destroy = true;
                disp('PROBLEM:::::::: Check this out !!!!!!!!!!!!!');
                break;
                %error('PROBLEM:::::::: Check this out !!!!!!!!!!!!!');
            end
            
        end
        
        % match
        coef_aray = [];
        loc_array = [];
        r_val = bin_array{i}.r_val;
       
        if bin_array{i}.destroy==true
           continue; 
        end
        
        %r_bin = create_rect( loc_to_match(2) - loc_to_match(1)+1, 3, r_val );
        
        if abs(loc_to_match(2) - loc_to_match(1)) >= thr * length(r_bin) && loc_to_match(2)-loc_to_match(1) < length(r_bin)
            r_bin = create_rect( loc_to_match(2) - loc_to_match(1)+1, 3, r_val );
        else
            if isfield(bin_array{i},'bin_or') && bin_array{i}.bin_or == "wide"
                r_bin = create_rect(r_wide_width, 5, r_val);
            else
                r_bin = create_rect(r_tall_width, 5, r_val);
            end
        end
        
        for j = loc_to_match(1): loc_to_match(2)- length(r_bin) + 1
            % width = bin_array{i}.limit(2) - bin_array{i}.limit(1)+1;
            I_d = calc_intens(I, [ j j+length(r_bin)-1 ]);
            coef = calc_coef_c11(r_bin, I_d, bin_array{i}.std);
            coef_aray = [ coef_aray coef ];
            loc_array = [loc_array j];
        end
        
        if isempty(coef_aray)
            bin_array(i).destroy = true;
            disp('coef array is empty');
            continue;
        end
        
       
        [ min_val , min_index] = min(coef_aray);
        min_loc = loc_array(min_index);
        loc_end = min_loc + length(r_bin)-1;
        
        %%% check wide
        if bin_array{i}.bin_or == "tall" && ...
                bin_array{i}.count < 150 && bin_array{i}.count >= 2
            
            lim_b = r_wide_width - r_tall_width;
            lim = 50;
            r_wide_val = bin_array{i}.r_val;
            
            r_wide = create_rect(r_wide_width, 5, r_wide_val);
            
            loc_to_match_w = loc_match(bin_array,i,loc_something,lim,lim_b);
            if abs(loc_to_match_w(2) - loc_to_match_w(1))> thr * length(r_wide)
                if loc_to_match_w(2)-loc_to_match_w(1) < length(r_wide)
                    r_wide = create_rect( loc_to_match_w(2) - loc_to_match_w(1)+1, 3, r_val);  %*0.8 );
                    
                end
                
                coef_aray_wide = [];
                loc_array_wide = [];
                for j = loc_to_match_w(1): loc_to_match_w(2)- length(r_wide) + 1
                    % width = bin_array{i}.limit(2) - bin_array{i}.limit(1)+1;
                    I_d = calc_intens(I, [ j j+length(r_wide)-1 ]);
                    coef = calc_coef_c11(r_wide, I_d, bin_array{i}.std);
                    coef_aray_wide = [ coef_aray_wide coef ];
                    loc_array_wide = [loc_array_wide j];
                end
                
                if ~isempty(coef_aray_wide)
                    [ min_val_wide , min_index_wide] = min(coef_aray_wide);
                    if min_val_wide < min_val  && abs(min_val_wide - min_val) >= 5
                        min_index = min_index_wide;
                        r_bin = r_wide;
                        
                        min_loc = loc_array_wide(min_index);
                        loc_end = min_loc + length(r_bin)-1;
                        
                        bin_array{i}.bin_or = "wide";
                        bin_array{i}.r_val = r_wide_val;
                        min_val = min_val_wide;
                        
                    end
                end
            end
        elseif bin_array{i}.state=="empty" && bin_array{i}.bin_or == "wide" && bin_array{i}.count < 150
            
            lim_b = 10;
            r_tall_w = r_tall_bin;
            
            loc_to_match_w = loc_match(bin_array,i,loc_something,lim,lim_b);
            if abs(loc_to_match_w(2) - loc_to_match_w(1))> thr * length(r_tall_w)
                if loc_to_match_w(2)-loc_to_match_w(1) < length(r_tall_w)
                    r_tall_w = create_rect( loc_to_match_w(2) - loc_to_match_w(1)+1, 3, r_val*0.8 );
                    
                end
                
                coef_aray_tall = [];
                loc_array_tall = [];
                for j = loc_to_match_w(1): loc_to_match_w(2)- length(r_tall_w) + 1
                    % width = bin_array{i}.limit(2) - bin_array{i}.limit(1)+1;
                    I_d = calc_intens(I, [ j j+length(r_tall_w)-1 ]);
                    coef = calc_coef_c11(r_tall_w, I_d, bin_array{i}.std);
                    coef_aray_tall = [ coef_aray_tall coef ];
                    loc_array_tall = [loc_array_tall j];
                end
                
                if ~isempty(coef_aray_tall)
                    [ min_val_t , min_index_t] = min(coef_aray_tall);
                    if min_val_t < min_val && abs(min_val_t-min_val) >= 5
                        min_index = min_index_t;
                        r_bin = r_tall_w;
                        
                        min_loc = loc_array_tall(min_index);
                        loc_end = min_loc + length(r_tall_w)-1;
                        
                        bin_array{i}.bin_or = "tall";
                        bin_array{i}.r_val = r_tall_val;
                        min_val = min_val_t;
                        
                    end
                end
            end
            
            
        end
        
        
        
        %% state calculation
        
        if min_val > 30 && bin_array{i}.state ~= "unspec"
            bin_array{i}.state = "unspec";
        end
        
        if bin_array{i}.state=="unspec"
            
            if ~isfield(bin_array{i}, 'recent_unspec')
                bin_array{i}.recent_unspec = [];
                bin_array{i}.recent_unspec(end+1) = min_val;
            else
                bin_array{i}.recent_unspec
                bin_array{i}.recent_unspec( end+1 ) = min_val;
                if length(bin_array{i}.recent_unspec) > 5
                    std_unspec = std(bin_array{i}.recent_unspec(end-4:end), 1);
                    if std_unspec < 15
                        % change state
                        if mean2( I(min_loc:loc_end, :)) > 110
                            % empty state
                            bin_array{i}.state = "empty";
                        else
                            bin_array{i}.state = "fill";
                            bin_array{i}.r_val = mean2( I(min_loc:loc_end, :));
                            
                        end
                        bin_array{i} = rmfield(bin_array{i}, 'recent_unspec');
                    end
                end
            end
        end
        
        
        height = loc_end - min_loc + 1;
        T_ = I( min_loc: min_loc+length(r_bin)-1, : );
        Loc = [  size(I,2)/2  min_loc+length(r_bin)/2-1 ];
        
        %%% draw
        if debug
            plot( min_loc:loc_end, r_bin );
            fprintf('%d :\n', i);
            disp("min loc :"+min_loc);
            disp("min value :"+min_val);
        end
        
        bin_array{i}.Area=size(T_,1)*size(T_,2);
        bin_array{i}.Centroid =  Loc';
        bin_array{i}.BoundingBox = [1 min_loc size(I,2) height ];
        bin_array{i}.limit= [ min_loc loc_end ] ;
        bin_array{i}.image=I( min_loc : loc_end , : );
        bin_array{i}.std =  std( calc_intens(I, [min_loc loc_end]) ,1);
        bin_array{i}.count = bin_array{i}.count + 1;
        loc_something(2) = min_loc;
        
    end
    
    % search lowest y
    min_ = inf;
    for i = 1:size(bin_array,2)
        if bin_array{i}.limit(1) < min_
            min_ = bin_array{i}.BoundingBox(2);
        end
    end
    
    loc_2 = min_;
    if loc_2 > loc_something(1) + r_tall_width * thr
        
        bins = match_template_signal_camera11( I, {}, [loc_something(1) loc_2], R_belt, R_c9, 0 );
        if ~isempty(bins)
            bin_array = {bin_array{:} bins{:}};
        end
    end
    
end

end
