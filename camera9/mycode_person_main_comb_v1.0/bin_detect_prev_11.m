function R_bin =  bin_detect_prev_11(im, im_flow, R_bin)

global scale;

thr = 0.8;

im_back = R_bin.im_back;

%% Set up parameters
threshold = R_bin.threshold;
dis_exit_y = R_bin.limit_exit_y * scale;%2401520;

%% Preprocessing
im_actual = im;

im_gray = rgb2gray(im_actual);
im_back_gray = rgb2gray(im_back);
im_r4 = abs(im_gray-im_back_gray) + abs(im_back_gray - im_gray);

imr4t = im_r4;

pt2 = [];

for i = 1: (size(imr4t,1))
    pt2(i) = ( mean( imr4t(i,:) ) );
end

loc = find( pt2 > threshold);
if ~isempty(loc)
    
    loc_something = [ loc(1) loc(end) ];
    
    I = uint8(zeros(size(im_actual,1), size(im_actual,2)));
    I(loc,:) = rgb2gray(im_actual(loc,:,:));
    
    
    %% match initial
    
    r_tall_val = 160;
    r_tall_width = floor(240 * scale);
    r_tall_bin = create_rect(r_tall_width, 5, r_tall_val);
    
    % create rectangular wide pulse
    r_wide_val = 140;
    r_wide_width = floor(280 * scale);
    r_wide = create_rect(r_wide_width, 5, r_wide_val);
    
    r_tall = r_tall_bin;
    
    coef_aray = [];
    loc_array = [];
    
    if isempty(loc_something)
        loc_something = [1 size(I,1)/2];
    end
    
    if loc_something(2) > size(I,1)*.6
        loc_something(2) = size(I,1)*.6;
    end
    
    %loc_end = loc_something(2) - length(r_tall) + 1;
    
    if abs(loc_something(2) - loc_something(1)) >= thr * length(r_tall)
        if abs(loc_something(2) - loc_something(1))> thr * length(r_tall) && loc_something(2)-loc_something(1) < length(r_tall)
            r_tall = ones(1, int64(loc_something(2) - loc_something(1)+1) );
            r_tall(1:3) = 0; r_tall(end-2:end) = 0;
            r_tall = r_tall * r_tall_val;
        end
        
        
        limit_std = 30;
        for i = loc_something(1): ( loc_something(2) -  length(r_tall) + 1 )
            I_d = calc_intens(I(:, 1:int32(size(I,2)*0.7)), [ i i+length(r_tall)-1 ]);
            %coef = sum(abs( r_tall - I_d )) / length(r_tall);
            coef = calc_coef_w(r_tall, I_d);
            
            if std(I_d(20:end-20)) > limit_std
                continue;
            end
            
            if coef > 70
                continue;
            end
            
            
            centre = (i + i+length(r_tall)-1) / 2;
            
            flag = 0;
            for j=1:numel(R_bin.bin_array)
                if abs(centre - R_bin.bin_array{j}.Centroid(2)) < R_bin.limit_distance
                    flag = 1;
                    break;
                end
            end
            if flag == 1
                continue;
            end
            
            coef_aray = [ coef_aray coef ];
            loc_array = [loc_array i];
            
        end
        
        if ~isempty(coef_aray)
            [ min_val , min_index] = min(coef_aray);
            min_loc = loc_array(min_index);
            
            loc_end = min_loc + length(r_tall)-1;
            height = loc_end - min_loc + 1;
            T_ = I( min_loc: min_loc+length(r_tall)-1, : );
            Loc = [  size(I,2)/2  min_loc+length(r_tall)/2-1 ];
            
            %%% draw
            % if debug
            %     plot( min_loc:loc_end, r_tall );
            %     %disp("min loc :"+min_loc);
            %     %disp("min value :"+min_val);
            % end
            
            Bin = struct( ...
                'Area',size(T_,1)*size(T_,2), 'Centroid', Loc, ...
                'BoundingBox', [1 min_loc size(I,2) height ], ...
                'limit', [ min_loc loc_end ] ,...
                'belongs_to', -1, ...
                'label', -1, 'tracker', [],...
                'in_flag', 1, 'r_val', r_tall_val, 'bin_or',"tall", ...
                'state', "empty", 'count', 1, ...
                'std', std(calc_intens(I, [min_loc loc_end]), 1), 'destroy', false ...
                );
            
            R_bin.bin_array{end+1} = Bin;
        end    
    end
end

%% tracking
bin_array = R_bin.bin_array;

del_exit = [];
for i = 1:numel(bin_array)
    
    if isempty(bin_array{i}.tracker)
        % init tracker
        tracker = R_bin.prev_bin{1}.tracker;%BACF_tracker(im, bin_array{i}.BoundingBox);
        new_pos = bin_array{i}.Centroid + [0 -50];
        tracker = tracker.setPos(new_pos,[]);
    else
        tracker = bin_array{i}.tracker;
      
    end
    
    [bin_array{i}.tracker, bb] = tracker.runTrack(im);
    bin_array{i}.BoundingBox = bb;
    bin_array{i}.Centroid = [bb(1)+bb(3)/2 bb(2)+bb(4)/2]';
    
    if abs(bin_array{i}.Centroid(1) - size(im,2)/2) > 30
        bbox = [1 bb(2) size(im,2) bb(4)];
        centroid = [size(im,2)/2 bin_array{i}.Centroid(2)];
        bin_array{i}.tracker = BACF_tracker(im, bbox);
        bin_array{i}.BoundingBox = bbox;
        bin_array{i}.Centroid = centroid;
    end
    
    if bin_array{i}.Centroid(2) > R_bin.limit_exit_y
        R_bin.bin_seq{end+1} = bin_array{i};
        del_exit(end+1) = i;
    end
end
bin_array(del_exit) = [];

R_bin.bin_array = bin_array;