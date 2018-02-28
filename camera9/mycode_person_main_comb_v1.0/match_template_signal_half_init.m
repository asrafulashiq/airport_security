function [bin_array] =  match_template_signal_half_init(I, loc_something, R_bin, flag, I_rgb)
global debug;
global scale;
global save_features;

obj_num = numel(R_bin.bin_array);
thr = 0.8;
bin_array = {};
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

limit_std = 50;
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

bin_array{end+1} = Bin;


%% save images bounding box for training
if save_features
    fname = fullfile(R_bin.imname,sprintf('%d_%s.jpg', R_bin.imno, R_bin.file_number));
    imwrite( I_rgb, fname);
    
    R_bin.filenames{end+1} = sprintf('%-20s',fname);
    R_bin.bb{end+1} = Bin.BoundingBox;
    
    R_bin.imno = R_bin.imno + 1;
end
end