function obj = setInit(obj, im)

params = obj.data.params;

%   Setting parameters for local use.
search_area_scale   = params.search_area_scale;
output_sigma_factor = params.output_sigma_factor;
learning_rate       = params.learning_rate;
filter_max_area     = params.filter_max_area;
nScales             = params.number_of_scales;
scale_step          = params.scale_step;
interpolate_response = params.interpolate_response;

features    = params.t_features;
%video_path  = params.video_path;
%s_frames    = params.s_frames;
pos         = floor(params.init_pos);
target_sz   = floor(params.wsize);

visualization  = params.visualization;
%num_frames     = params.no_fram;
init_target_sz = target_sz;


%set the feature ratio to the feature-cell size
featureRatio = params.t_global.cell_size;
search_area = prod(init_target_sz / featureRatio * search_area_scale);


% when the number of cells are small, choose a smaller cell size
if isfield(params.t_global, 'cell_selection_thresh')
    if search_area < params.t_global.cell_selection_thresh * filter_max_area
        params.t_global.cell_size = min(featureRatio, max(1, ceil(sqrt(prod(init_target_sz * search_area_scale)/(params.t_global.cell_selection_thresh * filter_max_area)))));
        
        featureRatio = params.t_global.cell_size;
        search_area = prod(init_target_sz / featureRatio * search_area_scale);
    end
end

global_feat_params = params.t_global;

if search_area > filter_max_area
    currentScaleFactor = sqrt(search_area / filter_max_area);
else
    currentScaleFactor = 1.0;
end

% target size at the initial scale
base_target_sz = target_sz / currentScaleFactor;


% window size, taking padding into account
switch params.search_area_shape
    case 'proportional'
        sz = floor( base_target_sz * search_area_scale);     % proportional area, same aspect ratio as the target
    case 'square'
        sz = repmat(sqrt(prod(base_target_sz * search_area_scale)), 1, 2); % square area, ignores the target aspect ratio
    case 'fix_padding'
        sz = base_target_sz + sqrt(prod(base_target_sz * search_area_scale) + (base_target_sz(1) - base_target_sz(2))/4) - sum(base_target_sz)/2; % const padding
    otherwise
        error('Unknown "params.search_area_shape". Must be ''proportional'', ''square'' or ''fix_padding''');
end

% set the size to exactly match the cell size
sz = round(sz / featureRatio) * featureRatio;
use_sz = floor(sz/featureRatio);

% construct the label function- correlation output, 2D gaussian function,
% with a peak located upon the target
output_sigma = sqrt(prod(floor(base_target_sz/featureRatio))) * output_sigma_factor;
rg           = circshift(-floor((use_sz(1)-1)/2):ceil((use_sz(1)-1)/2), [0 -floor((use_sz(1)-1)/2)]);
cg           = circshift(-floor((use_sz(2)-1)/2):ceil((use_sz(2)-1)/2), [0 -floor((use_sz(2)-1)/2)]);
[rs, cs]     = ndgrid( rg,cg);
y            = exp(-0.5 * (((rs.^2 + cs.^2) / output_sigma^2)));
yf           = fft2(y); %   FFT of y.

if interpolate_response == 1
    interp_sz = use_sz * featureRatio;
else
    interp_sz = use_sz;
end


% construct cosine window
cos_window = single(hann(use_sz(1))*hann(use_sz(2))');

% Calculate feaashiature dimension

if size(im,3) == 3
    if all(all(im(:,:,1) == im(:,:,2)))
        colorImage = false;
    else
        colorImage = true;
    end
else
    colorImage = false;
end

% compute feature dimensionality
feature_dim = 0;
for n = 1:length(features)
    
    if ~isfield(features{n}.fparams,'useForColor')
        features{n}.fparams.useForColor = true;
    end
    
    if ~isfield(features{n}.fparams,'useForGray')
        features{n}.fparams.useForGray = true;
    end
    
    if (features{n}.fparams.useForColor && colorImage) || (features{n}.fparams.useForGray && ~colorImage)
        feature_dim = feature_dim + features{n}.fparams.nDim;
    end
end

if size(im,3) > 1 && colorImage == false
    im = im(:,:,1);
end


if nScales > 0
    scale_exp = (-floor((nScales-1)/2):ceil((nScales-1)/2));
    scaleFactors = scale_step .^ scale_exp;
    min_scale_factor = scale_step ^ ceil(log(max(5 ./ sz)) / log(scale_step));
    max_scale_factor = scale_step ^ floor(log(min([size(im,1) size(im,2)] ./ base_target_sz)) / log(scale_step));
end

if interpolate_response >= 3
    % Pre-computes the grid that is used for socre optimization
    ky = circshift(-floor((use_sz(1) - 1)/2) : ceil((use_sz(1) - 1)/2), [1, -floor((use_sz(1) - 1)/2)]);
    kx = circshift(-floor((use_sz(2) - 1)/2) : ceil((use_sz(2) - 1)/2), [1, -floor((use_sz(2) - 1)/2)])';
    newton_iterations = params.newton_iterations;
end

% initialize the projection matrix (x,y,h,w)
%rect_position = zeros(num_frames, 4);
time = 0;

% allocate memory for multi-scale tracking
multires_pixel_template = zeros(sz(1), sz(2), size(im,3), nScales, 'uint8');
small_filter_sz = floor(base_target_sz/featureRatio);

loop_frame = 1;


%% set to obj
obj.data.pos = pos;
obj.data.target_sz = target_sz;
obj.data.currentScaleFactor = currentScaleFactor;
obj.data.base_target_sz  = base_target_sz;
obj.data.sz = sz;
obj.data.use_sz= use_sz;
obj.data.y = y;
obj.data.yf = yf;
obj.data.interp_sz = interp_sz;
obj.data.cos_window = cos_window;
obj.data.im = im;
obj.data.features = features;
obj.data.scaleFactors = scaleFactors;
obj.data.min_scale_factor = min_scale_factor;
obj.data.max_scale_factor = max_scale_factor;
obj.data.ky = ky;
obj.data.kx = kx;
obj.data.newton_iterations = newton_iterations;
%obj.data.rect_position = rect_position;
obj.data.time = time;
obj.data.multires_pixel_template = multires_pixel_template;
obj.data.small_filter_sz = small_filter_sz;
obj.data.loop_frame = loop_frame;
obj.data.frame = 0;
obj.data.currentScaleFactor = currentScaleFactor;

    
end