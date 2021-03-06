function bin_array =  match_template_signal(I, bin_array, loc_something)
global debug;

obj_num = size(bin_array,2);
thr = 0.7;
% create rectangular tall pulse


%%
r_tall_bin = create_rect(60, 5, 160);

% create rectangular wide pulse
r_wide = create_rect(80, 5, 110);
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
        r_tall = ones(1, loc_something(2) - loc_something(1)+1 );
        r_tall(1:3) = 0; r_tall(end-2:end) = 0;
        r_tall = r_tall * 160;
    end
    
    
    for i = loc_something(1): ( loc_something(2) -  length(r_tall) + 1 )
        I_d = calc_intens(I, [ i i+length(r_tall)-1 ]);
        %coef = sum(abs( r_tall - I_d )) / length(r_tall);
        coef = calc_coef_w(r_tall, I_d);
        
        if coef > 80
            continue;
        end
        coef_aray = [ coef_aray coef ];
        loc_array = [loc_array i];
        
    end
    
    %     for i = 1: size(I,1) / 2
    %         I_d = calc_intens(I, [ i i+length(r_wide)-1 ]);
    %         coef = mean( r_wide .* I_d ) / norm(r_wide) ;
    %         coef_aray = [ coef_aray coef ];
    %         loc_array = [loc_array i];
    %
    %     end
    
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
        disp("min loc :"+min_loc);
        disp("min value :"+min_val);
    end
    
    
    Bin = struct( ...
        'Area',size(T_,1)*size(T_,2), 'Centroid', Loc', ...
        'BoundingBox', [1 min_loc size(I,2) height ], ...
        'limit', [ min_loc loc_end ] ,...
        'image',I( min_loc : loc_end , : ), ...
        'belongs_to', -1, ...
        'label', -1, ...
        'in_flag', 1, 'r_val', 160, 'bin_or',"tall", ...
        'state', "empty", 'count', 1, ...
        'std', std( calc_intens(I, [min_loc loc_end]) ,1) ...
        );
    
    bin_array{end+1} = Bin;
    
    %     figure(4); imshow(I(min_loc:min_loc+59,:));
    %
    %      x = [];
    
else
    
    %loc_something = [ 1  size(I,1) ];
    
    for i = 1:obj_num
        
        r_tall = create_rect(60, 5, 160);
        
        
        lim = 20;
        lim_b = 5;
        loc_to_match = [];
        
        if isfield(bin_array{i},'bin_or') && bin_array{i}.bin_or=="wide"
            r_tall = create_rect(80, 5, bin_array{i}.r_val);
        end
        
        k = 0;
        while isempty(loc_to_match)
            
            loc_to_match = loc_match(bin_array,i,loc_something,lim,lim_b);
            
            if loc_to_match(2) < loc_to_match(1)
                bin_array{i} = [];
                continue;
            end
            
            if loc_to_match(2) - loc_to_match(1) < thr * length(r_tall)
                lim_b = lim_b + 5;
                lim = lim + 5;
                loc_to_match = [];
                k = k+1;
            end
            
            if k >5
                if isfield(bin_array{i},'bin_or') && bin_array{i}.bin_or=="wide"
                    r_tall = create_rect(60, 5, bin_array{i}.r_val);
                    bin_array{i}.r_val = 60;
                    bin_array{i}.bin_or = "tall";
                    loc_to_match = loc_match(bin_array,i,loc_something,lim,lim_b);
                    break;
%                 else
%                     r_tall = create_rect(60, 5, bin_array{i}.r_val);
%                     bin_array{i}.r_val = 60;
%                     bin_array{i}.bin_or = "tall";
%                     loc_to_match = loc_match(bin_array,i,loc_something,lim,lim_b);
                end
                
                error('PROBLEM:::::::: Check this out !!!!!!!!!!!!!');
            end
            
        end
        
        % match
        coef_aray = [];
        loc_array = [];
        r_val_tall = bin_array{i}.r_val;
       
        
        %r_tall = create_rect( loc_to_match(2) - loc_to_match(1)+1, 3, r_val_tall );
        
        if abs(loc_to_match(2) - loc_to_match(1)) >= thr * length(r_tall) && loc_to_match(2)-loc_to_match(1) < length(r_tall)
            r_tall = create_rect( loc_to_match(2) - loc_to_match(1)+1, 3, r_val_tall );
        else
            if isfield(bin_array{i},'bin_or') && bin_array{i}.bin_or == "wide"
                r_tall = create_rect(80, 5, r_val_tall);
            else
                r_tall = create_rect(60, 5, r_val_tall);
            end
        end
        
        for j = loc_to_match(1): loc_to_match(2)- length(r_tall) + 1
            % width = bin_array{i}.limit(2) - bin_array{i}.limit(1)+1;
            I_d = calc_intens(I, [ j j+length(r_tall)-1 ]);
            coef = calc_coef(r_tall, I_d, bin_array{i}.std);
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
        loc_end = min_loc + length(r_tall)-1;
        
        %%% check wide
        if bin_array{i}.state=="empty" && bin_array{i}.bin_or == "tall" && bin_array{i}.count < 150
            
            lim_b = 30;
            r_wide = create_rect(80, 5, 110);
            
            loc_to_match_w = loc_match(bin_array,i,loc_something,lim,lim_b);
            if abs(loc_to_match_w(2) - loc_to_match_w(1))> thr * length(r_wide)
                if loc_to_match_w(2)-loc_to_match_w(1) < length(r_wide)
                    r_wide = create_rect( loc_to_match_w(2) - loc_to_match_w(1)+1, 3, r_val_tall*0.8 );
                    
                end
                
                coef_aray_wide = [];
                loc_array_wide = [];
                for j = loc_to_match_w(1): loc_to_match_w(2)- length(r_wide) + 1
                    % width = bin_array{i}.limit(2) - bin_array{i}.limit(1)+1;
                    I_d = calc_intens(I, [ j j+length(r_wide)-1 ]);
                    coef = calc_coef(r_wide, I_d, bin_array{i}.std);
                    coef_aray_wide = [ coef_aray_wide coef ];
                    loc_array_wide = [loc_array_wide j];
                end
                
                if ~isempty(coef_aray_wide)
                    [ min_val_wide , min_index_wide] = min(coef_aray_wide);
                    if min_val_wide < min_val && abs(min_val_wide-min_val) >= 10
                        min_index = min_index_wide;
                        r_tall = r_wide;
                        
                        min_loc = loc_array_wide(min_index);
                        loc_end = min_loc + length(r_tall)-1;
                        
                        bin_array{i}.bin_or = "wide";
                        bin_array{i}.r_val = 110;
                        min_val = min_val_wide;
                        
                    end
                end
            end
        elseif bin_array{i}.state=="empty" && bin_array{i}.bin_or == "wide" && bin_array{i}.count < 150
            
            lim_b = 30;
            r_tall_w = r_tall_bin;
            
            loc_to_match_w = loc_match(bin_array,i,loc_something,lim,lim_b);
            if abs(loc_to_match_w(2) - loc_to_match_w(1))> thr * length(r_tall_w)
                if loc_to_match_w(2)-loc_to_match_w(1) < length(r_tall_w)
                    r_tall_w = create_rect( loc_to_match_w(2) - loc_to_match_w(1)+1, 3, r_val_tall*0.8 );
                    
                end
                
                coef_aray_tall = [];
                loc_array_tall = [];
                for j = loc_to_match_w(1): loc_to_match_w(2)- length(r_tall_w) + 1
                    % width = bin_array{i}.limit(2) - bin_array{i}.limit(1)+1;
                    I_d = calc_intens(I, [ j j+length(r_tall_w)-1 ]);
                    coef = calc_coef(r_tall_w, I_d, bin_array{i}.std);
                    coef_aray_tall = [ coef_aray_tall coef ];
                    loc_array_tall = [loc_array_tall j];
                end
                
                if ~isempty(coef_aray_tall)
                    [ min_val_t , min_index_t] = min(coef_aray_tall);
                    if min_val_t < min_val && abs(min_val_t-min_val) >= 10
                        min_index = min_index_t;
                        r_tall = r_tall_w;
                        
                        min_loc = loc_array_tall(min_index);
                        loc_end = min_loc + length(r_tall_w)-1;
                        
                        bin_array{i}.bin_or = "tall";
                        bin_array{i}.r_val = 160;
                        min_val = min_val_t;
                        
                    end
                end
            end
            
            
        end
        
        
        
        %% state calculation
        
        if min_val > 60 && bin_array{i}.state ~= "unspec"
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
                        if mean2( I(min_loc:loc_end, :)) > 90
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
        T_ = I( min_loc: min_loc+length(r_tall)-1, : );
        Loc = [  size(I,2)/2  min_loc+length(r_tall)/2-1 ];
        
        %%% draw
        if debug
            plot( min_loc:loc_end, r_tall );
            disp("min loc :"+min_loc);
            disp("min value :"+min_val);
        end
        
        bin_array{i}.Area=size(T_,1)*size(T_,2);
        bin_array{i}.Centroid =  Loc';
        bin_array{i}.BoundingBox = [1 min_loc size(I,2) height ];
        bin_array{i}.limit= [ min_loc loc_end ] ;
        bin_array{i}.image=I( min_loc : loc_end , : );
        %bin_array{i}.belongs_to= bin_array{i}.belongs_to;
        %bin_array{i}.label= bin_array{i}.label;
        %bin_array{i}.in_flag= bin_array{i}.in_flag;
        %bin_array{i}.state= bin_array{i}.state;
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
    if loc_2 > loc_something(1)
        
        bins = match_template_signal( I, {}, [loc_something(1) loc_2] );
        if ~isempty(bins)
            bin_array = {bin_array{:} bins{:}};
        end
    end
    
end

end
