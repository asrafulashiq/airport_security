function bin_array =  match_template_signal(I, bin_array, loc_something)
global debug;

obj_num = size(bin_array,2);
thr = 0.7;
% create rectangular tall pulse


%%
r_tall = create_rect(60, 5, 160);

% create rectangular wide pulse
r_wide = create_rect(80, 5, 110);

if obj_num == 0
    
    % match
    coef_aray = [];
    loc_array = [];
    
    if isempty(loc_something)
        loc_something = [1 size(I,1)/2];
    end
    
    if loc_something(2) > size(I,1)/2
       loc_something(2) = size(I,1)/2; 
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
        
        if coef > 60
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
        'in_flag', 1, ...
        'state', "empty", ...
        'std', std( calc_intens(I, [min_loc loc_end]) ,1) ...
        );
    
    bin_array{end+1} = Bin;
    
    %     figure(4); imshow(I(min_loc:min_loc+59,:));
    %
    %      x = [];
    
else
    
    %loc_something = [ 1  size(I,1) ];
    
    for i = 1:obj_num
        
        lim = 20;
        
        %%% loc to match
        if i > 1
            loc_end_match = min( bin_array{i}.limit(2)+lim, bin_array{i-1}.limit(1) );
        end
        if i < obj_num
            loc_strt_match = max(bin_array{i}.limit(1)-lim, bin_array{i+1}.limit(2)  );
        end
        if i==obj_num
            loc_strt_match = max(bin_array{i}.limit(1)-lim, loc_something(1) );
        end
        if i==1
            loc_end_match = min( bin_array{i}.limit(2)+lim, loc_something(2) );
        end
        
        
        loc_to_match = [loc_strt_match loc_end_match];
        
        % match
        coef_aray = [];
        loc_array = [];
        r_val_tall = 160;
        if bin_array{i}.state == "empty"
            r_val_tall = 160;
            r_val_wide = 100;
        elseif bin_array{i}.state == "fill"
            r_val_tall = bin_array{i}.r_val;
            %         elseif bin_array{i}.state == "unspec"
            %             r_val_tall = 100;
        end
        
        %r_tall = create_rect( loc_to_match(2) - loc_to_match(1)+1, 3, r_val_tall );
        
         if abs(loc_to_match(2) - loc_to_match(1))> thr * length(r_tall) && loc_to_match(2)-loc_to_match(1) < length(r_tall)
             r_tall = create_rect( loc_to_match(2) - loc_to_match(1)+1, 3, r_val_tall );
         else
             r_tall = create_rect(60, 5, r_val_tall);

         end
        
        for j = loc_to_match(1): loc_to_match(2)- length(r_tall) + 1
            % width = bin_array{i}.limit(2) - bin_array{i}.limit(1)+1;
            I_d = calc_intens(I, [ j j+length(r_tall)-1 ]);
            coef = calc_coef(r_tall, I_d, bin_array{i}.std);
            coef_aray = [ coef_aray coef ];
            loc_array = [loc_array j];
        end
        
        if isempty(coef_aray)
            bin_array(i) = [];
            disp('coef array is empty');
            continue;
        end
        
        
        
        [ min_val , min_index] = min(coef_aray);
        min_loc = loc_array(min_index);
        loc_end = min_loc + length(r_tall)-1;
        
        
        %% state calculation
        
        if min_val > 70 && bin_array{i}.state ~= "unspec"
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
                    std_unspec = std(bin_array{i}.recent_unspec(end-4:end), 1)
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
        bin_array{i}.belongs_to= bin_array{i}.belongs_to;
        bin_array{i}.label= bin_array{i}.label;
        bin_array{i}.in_flag= bin_array{i}.in_flag;
        bin_array{i}.state= bin_array{i}.state;
        bin_array{i}.std =  std( calc_intens(I, [min_loc loc_end]) ,1);
        
        
        
        
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