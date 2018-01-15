function obj = initTracker(obj, im, rect)

params = obj.data.params;

% Get sequence info
[seq] = obj.get_sequence_info( rect);
%params = rmfield(params, 'seq');
if isempty(im)
    seq.rect_position = [];
    return;
end


% Init position
pos = seq.init_pos(:)';
target_sz = seq.init_sz(:)';
params.init_sz = target_sz;

% Feature settings
features = params.t_features;

% Set default parameters
params = obj.init_default_params(params);

% Global feature parameters
if isfield(params, 't_global')
    global_fparams = params.t_global;
else
    global_fparams = [];
end
global_fparams.use_gpu = params.use_gpu;
global_fparams.gpu_id = params.gpu_id;

% Correct max number of samples
params.nSamples = min(params.nSamples, 1000);

% Define data types
if params.use_gpu
    params.data_type = zeros(1, 'single', 'gpuArray');
else
    params.data_type = zeros(1, 'single');
end
params.data_type_complex = complex(params.data_type);
global_fparams.data_type = params.data_type;

init_target_sz = target_sz;


% Check if color image
if size(im,3) == 3
    if all(all(im(:,:,1) == im(:,:,2)))
        is_color_image = false;
    else
        is_color_image = true;
    end
else
    is_color_image = false;
end

if size(im,3) > 1 && is_color_image == false
    im = im(:,:,1);
end


% Check if mexResize is available and show warning otherwise.
params.use_mexResize = true;
global_fparams.use_mexResize = true;
try
    [~] = mexResize(ones(5,5,3,'uint8'), [3 3], 'auto');
catch err
    warning('ECO:tracker', 'Error when using the mexResize function. Using Matlab''s interpolation function instead, which is slower.\nTry to run the compile script in "external_libs/mexResize/".\n\nThe error was:\n%s', getReport(err));
    params.use_mexResize = false;
    global_fparams.use_mexResize = false;
end


% Calculate search area and initial scale factor
search_area = prod(init_target_sz * params.search_area_scale);
if search_area > params.max_image_sample_size
    currentScaleFactor = sqrt(search_area / params.max_image_sample_size);
elseif search_area < params.min_image_sample_size
    currentScaleFactor = sqrt(search_area / params.min_image_sample_size);
else
    currentScaleFactor = 1.0;
end

% target size at the initial scale
base_target_sz = target_sz / currentScaleFactor;


% window size, taking padding into account
switch params.search_area_shape
    case 'proportional'
        img_sample_sz = floor( base_target_sz * params.search_area_scale);     % proportional area, same aspect ratio as the target
    case 'square'
        img_sample_sz = repmat(sqrt(prod(base_target_sz * params.search_area_scale)), 1, 2); % square area, ignores the target aspect ratio
    case 'fix_padding'
        img_sample_sz = base_target_sz + sqrt(prod(base_target_sz * params.search_area_scale) + (base_target_sz(1) - base_target_sz(2))/4) - sum(base_target_sz)/2; % const padding
    case 'custom'
        img_sample_sz = [base_target_sz(1)*2 base_target_sz(2)*2]; % for testing
end

[features, global_fparams, feature_info] = obj.init_features(features, global_fparams, is_color_image, img_sample_sz, 'odd_cells');


% Set feature info
img_support_sz = feature_info.img_support_sz;
feature_sz = feature_info.data_sz;
feature_dim = feature_info.dim;
num_feature_blocks = length(feature_dim);

% Get feature specific parameters
feature_params = obj.init_feature_params(features, feature_info);
feature_extract_info = obj.get_feature_extract_info(features);

% Set the sample feature dimension
if params.use_projection_matrix
    sample_dim = feature_params.compressed_dim;
else
    sample_dim = feature_dim;
end


% Size of the extracted feature maps
feature_sz_cell = permute(mat2cell(feature_sz, ones(1,num_feature_blocks), 2), [2 3 1]);

% Number of Fourier coefficients to save for each filter layer. This will
% be an odd number.
filter_sz = feature_sz + mod(feature_sz+1, 2);
filter_sz_cell = permute(mat2cell(filter_sz, ones(1,num_feature_blocks), 2), [2 3 1]);

% The size of the label function DFT. Equal to the maximum filter size.
[output_sz, k1] = max(filter_sz, [], 1);
k1 = k1(1);

% Get the remaining block indices
block_inds = 1:num_feature_blocks;
block_inds(k1) = [];

% How much each feature block has to be padded to the obtain output_sz
pad_sz = cellfun(@(filter_sz) (output_sz - filter_sz) / 2, filter_sz_cell, 'uniformoutput', false);

% Compute the Fourier series indices and their transposes
ky = cellfun(@(sz) (-ceil((sz(1) - 1)/2) : floor((sz(1) - 1)/2))', filter_sz_cell, 'uniformoutput', false);
kx = cellfun(@(sz) -ceil((sz(2) - 1)/2) : 0, filter_sz_cell, 'uniformoutput', false);

% construct the Gaussian label function using Poisson formula
sig_y = sqrt(prod(floor(base_target_sz))) * params.output_sigma_factor * (output_sz ./ img_support_sz);
yf_y = cellfun(@(ky) single(sqrt(2*pi) * sig_y(1) / output_sz(1) * exp(-2 * (pi * sig_y(1) * ky / output_sz(1)).^2)), ky, 'uniformoutput', false);
yf_x = cellfun(@(kx) single(sqrt(2*pi) * sig_y(2) / output_sz(2) * exp(-2 * (pi * sig_y(2) * kx / output_sz(2)).^2)), kx, 'uniformoutput', false);
yf = cellfun(@(yf_y, yf_x) cast(yf_y * yf_x, 'like', params.data_type), yf_y, yf_x, 'uniformoutput', false);

% construct cosine window
cos_window = cellfun(@(sz) hann(sz(1)+2)*hann(sz(2)+2)', feature_sz_cell, 'uniformoutput', false);
cos_window = cellfun(@(cos_window) cast(cos_window(2:end-1,2:end-1), 'like', params.data_type), cos_window, 'uniformoutput', false);

% Compute Fourier series of interpolation function
[interp1_fs, interp2_fs] = cellfun(@(sz) obj.get_interp_fourier(sz, params), filter_sz_cell, 'uniformoutput', false);

% Get the reg_window_edge parameter
reg_window_edge = {};
for k = 1:length(features)
    if isfield(features{k}.fparams, 'reg_window_edge')
        reg_window_edge = cat(3, reg_window_edge, permute(num2cell(features{k}.fparams.reg_window_edge(:)), [2 3 1]));
    else
        reg_window_edge = cat(3, reg_window_edge, cell(1, 1, length(features{k}.fparams.nDim)));
    end
end


% Construct spatial regularization filter
reg_filter = cellfun(@(reg_window_edge) get_reg_filter(img_support_sz, base_target_sz, params, reg_window_edge), reg_window_edge, 'uniformoutput', false);

% Compute the energy of the filter (used for preconditioner)
reg_energy = cellfun(@(reg_filter) real(reg_filter(:)' * reg_filter(:)), reg_filter, 'uniformoutput', false);


if params.use_scale_filter
    [nScales, scale_step, scaleFactors, scale_filter, params] = obj.init_scale_filter(params);
else
    % Use the translation filter to estimate the scale.
    nScales = params.number_of_scales;
    scale_step = params.scale_step;
    scale_exp = (-floor((nScales-1)/2):ceil((nScales-1)/2));
    scaleFactors = scale_step .^ scale_exp;
end

if nScales > 0
    %force reasonable scale changes
    min_scale_factor = scale_step ^ ceil(log(max(5 ./ img_support_sz)) / log(scale_step));
    max_scale_factor = scale_step ^ floor(log(min([size(im,1) size(im,2)] ./ base_target_sz)) / log(scale_step));
end

% Set conjugate gradient uptions
init_CG_opts.CG_use_FR = true;
init_CG_opts.tol = 1e-6;
init_CG_opts.CG_standard_alpha = true;
init_CG_opts.debug = params.debug;
CG_opts.CG_use_FR = params.CG_use_FR;
CG_opts.tol = 1e-6;
CG_opts.CG_standard_alpha = params.CG_standard_alpha;
CG_opts.debug = params.debug;
if params.CG_forgetting_rate == Inf || params.learning_rate >= 1
    CG_opts.init_forget_factor = 0;
else
    CG_opts.init_forget_factor = (1-params.learning_rate)^params.CG_forgetting_rate;
end

seq.time = 0;

% Initialize and allocate
prior_weights = zeros(params.nSamples,1, 'single');
sample_weights = cast(prior_weights, 'like', params.data_type);
samplesf = cell(1, 1, num_feature_blocks);
if params.use_gpu
    % In the GPU version, the data is stored in a more normal way since we
    % dont have to use mtimesx.
    for k = 1:num_feature_blocks
        samplesf{k} = zeros(filter_sz(k,1),(filter_sz(k,2)+1)/2,sample_dim(k),params.nSamples, 'like', params.data_type_complex);
    end
else
    for k = 1:num_feature_blocks
        samplesf{k} = zeros(params.nSamples,sample_dim(k),filter_sz(k,1),(filter_sz(k,2)+1)/2, 'like', params.data_type_complex);
    end
end


% Allocate
scores_fs_feat = cell(1,1,num_feature_blocks);

% Distance matrix stores the square of the euclidean distance between each pair of
% samples. Initialise it to inf
distance_matrix = inf(params.nSamples, 'single');

% Kernel matrix, used to update distance matrix
gram_matrix = inf(params.nSamples, 'single');


latest_ind = [];
frames_since_last_train = inf;
num_training_samples = 0;

% Find the minimum allowed sample weight. Samples are discarded if their weights become lower 
params.minimum_sample_weight = params.learning_rate*(1-params.learning_rate)^(2*params.nSamples);

res_norms = [];
residuals_pcg = [];

%% set object properties
obj.data.params = params;

%% set data properties
data.scores_fs_feat = scores_fs_feat; data.distance_matrix = distance_matrix; data.gram_matrix = gram_matrix;
data.latest_ind = latest_ind; data.frames_since_last_train = frames_since_last_train; 
data.num_training_samples = num_training_samples;
data.res_norms = res_norms; data.residuals_pcg = residuals_pcg;

data.pos = pos; 
data.seq = seq;
data.target_sz = target_sz;
data.params = params;
data.features = features;
data.global_fparams = global_fparams;
data.im = im;
data.currentScaleFactor = currentScaleFactor;
data.base_target_sz = base_target_sz;
data.feature_info = feature_info;
data.img_support_sz = img_support_sz;
data.feature_dim = feature_dim;
data.num_feature_blocks = num_feature_blocks;
data.feature_extract_info = feature_extract_info;
data.sample_dim = sample_dim;
data.output_sz = output_sz;
data.k1 = k1;
data.block_inds = block_inds;
data.pad_sz = pad_sz;
data.ky = ky;
data.kx = kx;
data.yf = yf;
data.cos_window = cos_window;
data.interp1_fs = interp1_fs;
data.interp2_fs = interp2_fs;
data.reg_filter = reg_filter;
data.reg_energy = reg_energy;
data.nScales = nScales; 
data.scaleFactors = scaleFactors; 
data.scale_filter = [];%scale_filter;
data.min_scale_factor = min_scale_factor; 
data.max_scale_factor = max_scale_factor;
data.init_CG_opts = init_CG_opts; 
data.CG_opts = CG_opts;
data.prior_weights = prior_weights; data.sample_weights = sample_weights; data.samplesf = samplesf;
data.filter_sz = filter_sz;


obj.data = data;

end