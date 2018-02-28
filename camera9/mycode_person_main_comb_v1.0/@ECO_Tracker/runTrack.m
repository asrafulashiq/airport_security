function [obj, rect_position_vis] = runTrack(obj, im)

%% get object properties
scores_fs_feat = obj.data.scores_fs_feat;
distance_matrix = obj.data.distance_matrix;
gram_matrix = obj.data.gram_matrix;
latest_ind = obj.data.latest_ind;
frames_since_last_train = obj.data.frames_since_last_train;
num_training_samples = obj.data.num_training_samples;
res_norms = obj.data.res_norms;
residuals_pcg = obj.data.residuals_pcg;
pos = obj.data.pos;
seq = obj.data.seq;
target_sz = obj.data.target_sz;
params = obj.data.params;
features = obj.data.features;
global_fparams = obj.data.global_fparams;
%im = obj.data.im;
currentScaleFactor = obj.data.currentScaleFactor;
base_target_sz = obj.data.base_target_sz;
feature_info = obj.data.feature_info;
img_support_sz = obj.data.img_support_sz;
feature_dim = obj.data.feature_dim;
num_feature_blocks = obj.data.num_feature_blocks;
feature_extract_info = obj.data.feature_extract_info;
sample_dim = obj.data.sample_dim;
output_sz = obj.data.output_sz;
k1 = obj.data.k1;
block_inds = obj.data.block_inds;
pad_sz = obj.data.pad_sz;
ky = obj.data.ky;
kx = obj.data.kx;
yf = obj.data.yf;
cos_window = obj.data.cos_window;
interp1_fs = obj.data.interp1_fs;
interp2_fs = obj.data.interp2_fs;
reg_filter = obj.data.reg_filter;
reg_energy = obj.data.reg_energy;
nScales = obj.data.nScales;
scaleFactors = obj.data.scaleFactors;
scale_filter = obj.data.scale_filter;
min_scale_factor = obj.data.min_scale_factor;
max_scale_factor = obj.data.max_scale_factor;
init_CG_opts = obj.data.init_CG_opts;
CG_opts = obj.data.CG_opts;
prior_weights = obj.data.prior_weights;
sample_weights = obj.data.sample_weights;
samplesf = obj.data.samplesf;
filter_sz = obj.data.filter_sz;

%% from 1
if isfield(obj.data, 'projection_matrix')
    projection_matrix = obj.data.projection_matrix;
end

if isfield(obj.data, 'hf_full')
    hf_full = obj.data.hf_full;
end

if isfield(obj.data, 'sample_energy')
    sample_energy = obj.data.sample_energy;
end

if isfield(obj.data, 'hf')
    hf = obj.data.hf;
end

if isfield(obj.data, 'CG_state')
    CG_state = obj.data.CG_state;
end

%%
seq.frame = seq.frame+1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Target localization step
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Do not estimate translation and scaling on the first frame, since we
% just want to initialize the tracker there
tic();

if seq.frame > 1
    old_pos = inf(size(pos));
    iter = 1;
    
    %translation search
    while iter <= params.refinement_iterations && any(old_pos ~= pos)
        % Extract features at multiple resolutions
        sample_pos = round(pos);
        det_sample_pos = sample_pos;
        sample_scale = currentScaleFactor*scaleFactors;
        xt = extract_features(im, sample_pos, sample_scale, features, global_fparams, feature_extract_info);
        
        % Project sample
        xt_proj = project_sample(xt, projection_matrix);
        
        % Do windowing of features
        xt_proj = cellfun(@(feat_map, cos_window) bsxfun(@times, feat_map, cos_window), xt_proj, cos_window, 'uniformoutput', false);
        
        % Compute the fourier series
        xtf_proj = cellfun(@cfft2, xt_proj, 'uniformoutput', false);
        
        % Interpolate features to the continuous domain
        xtf_proj = interpolate_dft(xtf_proj, interp1_fs, interp2_fs);
        
        % Compute convolution for each feature block in the Fourier domain
        % and the sum over all blocks.
        scores_fs_feat{k1} = sum(bsxfun(@times, hf_full{k1}, xtf_proj{k1}), 3);
        scores_fs_sum = scores_fs_feat{k1};
        for k = block_inds
            scores_fs_feat{k} = sum(bsxfun(@times, hf_full{k}, xtf_proj{k}), 3);
            scores_fs_sum(1+pad_sz{k}(1):end-pad_sz{k}(1), 1+pad_sz{k}(2):end-pad_sz{k}(2),1,:) = ...
                scores_fs_sum(1+pad_sz{k}(1):end-pad_sz{k}(1), 1+pad_sz{k}(2):end-pad_sz{k}(2),1,:) + ...
                scores_fs_feat{k};
        end
        
        % Also sum over all feature blocks.
        % Gives the fourier coefficients of the convolution response.
        scores_fs = permute(gather(scores_fs_sum), [1 2 4 3]);
        
        % Optimize the continuous score function with Newton's method.
        [trans_row, trans_col, scale_ind] = optimize_scores(scores_fs, params.newton_iterations);
        
        % Compute the translation vector in pixel-coordinates and round
        % to the closest integer pixel.
        translation_vec = [trans_row, trans_col] .* (img_support_sz./output_sz) * currentScaleFactor * scaleFactors(scale_ind);
        scale_change_factor = scaleFactors(scale_ind);
        
        % update position
        old_pos = pos;
        pos = sample_pos + translation_vec;
        
        if params.clamp_position
            pos = max([1 1], min([size(im,1) size(im,2)], pos));
        end
        
        % Do scale tracking with the scale filter
        if nScales > 0 && params.use_scale_filter
            scale_change_factor = scale_filter_track(im, pos, base_target_sz, currentScaleFactor, scale_filter, params);
        end
        
        % Update the scale
        currentScaleFactor = currentScaleFactor * scale_change_factor;
        
        % Adjust to make sure we are not to large or to small
        if currentScaleFactor < min_scale_factor
            currentScaleFactor = min_scale_factor;
        elseif currentScaleFactor > max_scale_factor
            currentScaleFactor = max_scale_factor;
        end
        
        iter = iter + 1;
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Model update step
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Extract sample and init projection matrix
if seq.frame == 1
    % Extract image region for training sample
    sample_pos = round(pos);
    sample_scale = currentScaleFactor;
    xl = extract_features(im, sample_pos, currentScaleFactor, features, global_fparams, feature_extract_info);
    
    % Do windowing of features
    xlw = cellfun(@(feat_map, cos_window) bsxfun(@times, feat_map, cos_window), xl, cos_window, 'uniformoutput', false);
    
    % Compute the fourier series
    xlf = cellfun(@cfft2, xlw, 'uniformoutput', false);
    
    % Interpolate features to the continuous domain
    xlf = interpolate_dft(xlf, interp1_fs, interp2_fs);
    
    % New sample to be added
    xlf = compact_fourier_coeff(xlf);
    
    % Shift sample
    shift_samp = 2*pi * (pos - sample_pos) ./ (sample_scale * img_support_sz);
    xlf = shift_sample(xlf, shift_samp, kx, ky);
    
    % Init the projection matrix
    projection_matrix = init_projection_matrix(xl, sample_dim, params);
    
    % Project sample
    xlf_proj = project_sample(xlf, projection_matrix);
    
    clear xlw
elseif params.learning_rate > 0
    if ~params.use_detection_sample
        % Extract image region for training sample
        sample_pos = round(pos);
        sample_scale = currentScaleFactor;
        xl = extract_features(im, sample_pos, currentScaleFactor, features, global_fparams, feature_extract_info);
        
        % Project sample
        xl_proj = project_sample(xl, projection_matrix);
        
        % Do windowing of features
        xl_proj = cellfun(@(feat_map, cos_window) bsxfun(@times, feat_map, cos_window), xl_proj, cos_window, 'uniformoutput', false);
        
        % Compute the fourier series
        xlf1_proj = cellfun(@cfft2, xl_proj, 'uniformoutput', false);
        
        % Interpolate features to the continuous domain
        xlf1_proj = interpolate_dft(xlf1_proj, interp1_fs, interp2_fs);
        
        % New sample to be added
        xlf_proj = compact_fourier_coeff(xlf1_proj);
    else
        if params.debug
            % Only for visualization
            xl = cellfun(@(xt) xt(:,:,:,scale_ind), xt, 'uniformoutput', false);
        end
        
        % Use the sample that was used for detection
        sample_scale = sample_scale(scale_ind);
        xlf_proj = cellfun(@(xf) xf(:,1:(size(xf,2)+1)/2,:,scale_ind), xtf_proj, 'uniformoutput', false);
    end
    
    % Shift the sample so that the target is centered
    shift_samp = 2*pi * (pos - sample_pos) ./ (sample_scale * img_support_sz);
    xlf_proj = shift_sample(xlf_proj, shift_samp, kx, ky);
end

% The permuted sample is only needed for the CPU implementation
if ~params.use_gpu
    xlf_proj_perm = cellfun(@(xf) permute(xf, [4 3 1 2]), xlf_proj, 'uniformoutput', false);
end

if params.use_sample_merge
    % Update the samplesf to include the new sample. The distance
    % matrix, kernel matrix and prior weight are also updated
    if params.use_gpu
        [merged_sample, new_sample, merged_sample_id, new_sample_id, distance_matrix, gram_matrix, prior_weights] = ...
            update_sample_space_model_gpu(samplesf, xlf_proj, distance_matrix, gram_matrix, prior_weights,...
            num_training_samples,params);
    else
        [merged_sample, new_sample, merged_sample_id, new_sample_id, distance_matrix, gram_matrix, prior_weights] = ...
            update_sample_space_model(samplesf, xlf_proj_perm, distance_matrix, gram_matrix, prior_weights,...
            num_training_samples,params);
    end
    
    if num_training_samples < params.nSamples
        num_training_samples = num_training_samples + 1;
    end
else
    % Do the traditional adding of a training sample and weight update
    % of C-COT
    [prior_weights, replace_ind] = update_prior_weights(prior_weights, gather(sample_weights), latest_ind, seq.frame, params);
    latest_ind = replace_ind;
    
    merged_sample_id = 0;
    new_sample_id = replace_ind;
    if params.use_gpu
        new_sample = xlf_proj;
    else
        new_sample = xlf_proj_perm;
    end
end

if seq.frame > 1 && params.learning_rate > 0 || seq.frame == 1 && ~params.update_projection_matrix
    % Insert the new training sample
    for k = 1:num_feature_blocks
        if params.use_gpu
            if merged_sample_id > 0
                samplesf{k}(:,:,:,merged_sample_id) = merged_sample{k};
            end
            if new_sample_id > 0
                samplesf{k}(:,:,:,new_sample_id) = new_sample{k};
            end
        else
            if merged_sample_id > 0
                samplesf{k}(merged_sample_id,:,:,:) = merged_sample{k};
            end
            if new_sample_id > 0
                samplesf{k}(new_sample_id,:,:,:) = new_sample{k};
            end
        end
    end
end

sample_weights = cast(prior_weights, 'like', params.data_type);

train_tracker = (seq.frame < params.skip_after_frame) || (frames_since_last_train >= params.train_gap);

if train_tracker
    % Used for preconditioning
    new_sample_energy = cellfun(@(xlf) abs(xlf .* conj(xlf)), xlf_proj, 'uniformoutput', false);
    
    if seq.frame == 1
        % Initialize stuff for the filter learning
        
        % Initialize Conjugate Gradient parameters
        sample_energy = new_sample_energy;
        CG_state = [];
        
        if params.update_projection_matrix
            % Number of CG iterations per GN iteration
            init_CG_opts.maxit = ceil(params.init_CG_iter / params.init_GN_iter);
            
            hf = cell(2,1,num_feature_blocks);
            proj_energy = cellfun(@(P, yf) 2*sum(abs(yf(:)).^2) / sum(feature_dim) * ones(size(P), 'like', params.data_type), projection_matrix, yf, 'uniformoutput', false);
        else
            CG_opts.maxit = params.init_CG_iter; % Number of initial iterations if projection matrix is not updated
            
            hf = cell(1,1,num_feature_blocks);
        end
        
        % Initialize the filter with zeros
        for k = 1:num_feature_blocks
            hf{1,1,k} = zeros([filter_sz(k,1) (filter_sz(k,2)+1)/2 sample_dim(k)], 'like', params.data_type_complex);
        end
    else
        CG_opts.maxit = params.CG_iter;
        
        % Update the approximate average sample energy using the learning
        % rate. This is only used to construct the preconditioner.
        sample_energy = cellfun(@(se, nse) (1 - params.learning_rate) * se + params.learning_rate * nse, sample_energy, new_sample_energy, 'uniformoutput', false);
    end
    
    % Do training
    if seq.frame == 1 && params.update_projection_matrix
        if params.debug
            projection_matrix_init = projection_matrix;
        end
        
        % Initial Gauss-Newton optimization of the filter and
        % projection matrix.
        if params.use_gpu
            [hf, projection_matrix, res_norms] = train_joint_gpu(hf, projection_matrix, xlf, yf, reg_filter, sample_energy, reg_energy, proj_energy, params, init_CG_opts);
        else
            [hf, projection_matrix, res_norms] = train_joint(hf, projection_matrix, xlf, yf, reg_filter, sample_energy, reg_energy, proj_energy, params, init_CG_opts);
        end
        
        % Re-project and insert training sample
        xlf_proj = project_sample(xlf, projection_matrix);
        for k = 1:num_feature_blocks
            if params.use_gpu
                samplesf{k}(:,:,:,1) = xlf_proj{k};
            else
                samplesf{k}(1,:,:,:) = permute(xlf_proj{k}, [4 3 1 2]);
            end
        end
        
        % Update the gram matrix since the sample has changed
        if strcmp(params.distance_matrix_update_type, 'exact')
            % Find the norm of the reprojected sample
            new_train_sample_norm =  0;
            
            for k = 1:num_feature_blocks
                new_train_sample_norm = new_train_sample_norm + real(gather(2*(xlf_proj{k}(:)' * xlf_proj{k}(:))));% - reshape(xlf_proj{k}(:,end,:,:), [], 1, 1)' * reshape(xlf_proj{k}(:,end,:,:), [], 1, 1));
            end
            
            gram_matrix(1,1) = new_train_sample_norm;
        end
        
        if params.debug
            norm_proj_mat_init = sqrt(sum(cellfun(@(P) gather(norm(P(:))^2), projection_matrix_init)));
            norm_proj_mat = sqrt(sum(cellfun(@(P) gather(norm(P(:))^2), projection_matrix)));
            norm_proj_mat_change = sqrt(sum(cellfun(@(P,P2) gather(norm(P(:) - P2(:))^2), projection_matrix_init, projection_matrix)));
            fprintf('Norm init: %f, Norm final: %f, Matrix change: %f\n', norm_proj_mat_init, norm_proj_mat, norm_proj_mat_change / norm_proj_mat_init);
        end
    else
        % Do Conjugate gradient optimization of the filter
        if params.use_gpu
            [hf, res_norms, CG_state] = train_filter_gpu(hf, samplesf, yf, reg_filter, sample_weights, sample_energy, reg_energy, params, CG_opts, CG_state);
        else
            [hf, res_norms, CG_state] = train_filter(hf, samplesf, yf, reg_filter, sample_weights, sample_energy, reg_energy, params, CG_opts, CG_state);
        end
    end
    
    % Reconstruct the full Fourier series
    hf_full = full_fourier_coeff(hf);
    
    frames_since_last_train = 0;
else
    frames_since_last_train = frames_since_last_train+1;
end



%% update object parameters
obj.data.scores_fs_feat = scores_fs_feat;
obj.data.projection_matrix = projection_matrix;
% if exist('scale_ind', 1)
%     obj.data.scale_ind = scale_ind;
% end
obj.data.sample_scale = sample_scale;
obj.data.hf_full = hf_full;


% Update the scale filter
if nScales > 0 && params.use_scale_filter
    scale_filter = scale_filter_update(im, pos, base_target_sz, currentScaleFactor, scale_filter, params);
end

% Update the target size (only used for computing output box)
target_sz = base_target_sz * currentScaleFactor;

%save position and calculate FPS
tracking_result.center_pos = double(pos);
tracking_result.target_size = double(target_sz);
seq = obj.report_tracking_result(seq, tracking_result);

seq.time = seq.time + toc();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Visualization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rect_position_vis = [pos([2,1]) - (target_sz([2,1]) - 1)/2, target_sz([2,1])];
if params.visualization
    
    im_to_show = double(im)/255;
    if size(im_to_show,3) == 1
        im_to_show = repmat(im_to_show, [1 1 3]);
    end
    if seq.frame == 1  %first frame, create GUI
        
        figure(1);imshow(im_to_show);
        hold on;
        rectangle('Position',rect_position_vis, 'EdgeColor','g', 'LineWidth',2);
        text(10, 10, int2str(seq.frame), 'color', [0 1 1]);
        hold off;
        axis off;axis image;set(gca, 'Units', 'normalized', 'Position', [0 0 1 1])
        
    else
        % Do visualization of the sampled confidence scores overlayed
        resp_sz = round(img_support_sz*currentScaleFactor*scaleFactors(scale_ind));
        xs = floor(det_sample_pos(2)) + (1:resp_sz(2)) - floor(resp_sz(2)/2);
        ys = floor(det_sample_pos(1)) + (1:resp_sz(1)) - floor(resp_sz(1)/2);
        
        % To visualize the continuous scores, sample them 10 times more
        % dense than output_sz.
        sampled_scores_display = fftshift(sample_fs(scores_fs(:,:,scale_ind), 10*output_sz));
        
        %figure(fig_handle);
        figure(1);
        imshow(im_to_show);
        %imagesc(im_to_show);
        hold on;
        %resp_handle = imagesc(xs, ys, sampled_scores_display); colormap hsv;
        %alpha(resp_handle, 0.5);
        rectangle('Position',rect_position_vis, 'EdgeColor','g', 'LineWidth',2);
        disp(rect_position_vis);
        text(10, 10, int2str(seq.frame), 'color', [0 1 1]);
        hold off;
        
        %                 axis off;axis image;set(gca, 'Units', 'normalized', 'Position', [0 0 1 1])
    end
    
    drawnow
    
    
    
end

%% set object properties
obj.data.scores_fs_feat = scores_fs_feat; obj.data.distance_matrix = distance_matrix; obj.data.gram_matrix = gram_matrix;
obj.data.latest_ind = latest_ind; obj.data.frames_since_last_train = frames_since_last_train;
obj.data.num_training_samples = num_training_samples;
obj.data.res_norms = res_norms; obj.data.residuals_pcg = residuals_pcg;

obj.data.pos = pos;
obj.data.seq = seq;
obj.data.target_sz = target_sz;
obj.data.params = params;
obj.data.features = features;
obj.data.global_fparams = global_fparams;
obj.data.im = im;
obj.data.currentScaleFactor = currentScaleFactor;
obj.data.base_target_sz = base_target_sz;
obj.data.feature_info = feature_info;
obj.data.img_support_sz = img_support_sz;
obj.data.feature_dim = feature_dim;
obj.data.num_feature_blocks = num_feature_blocks;
obj.data.feature_extract_info = feature_extract_info;
obj.data.sample_dim = sample_dim;
obj.data.output_sz = output_sz;
obj.data.k1 = k1;
obj.data.block_inds = block_inds;
obj.data.pad_sz = pad_sz;
obj.data.ky = ky;
obj.data.kx = kx;
obj.data.yf = yf;
obj.data.cos_window = cos_window;
obj.data.interp1_fs = interp1_fs;
obj.data.interp2_fs = interp2_fs;
obj.data.reg_filter = reg_filter;
obj.data.reg_energy = reg_energy;
obj.data.nScales = nScales; obj.data.scaleFactors = scaleFactors; obj.data.scale_filter = scale_filter;
obj.data.min_scale_factor = min_scale_factor; obj.data.max_scale_factor = max_scale_factor;
obj.data.init_CG_opts = init_CG_opts; obj.data.CG_opts = CG_opts;
obj.data.prior_weights = prior_weights; obj.data.sample_weights = sample_weights; obj.data.samplesf = samplesf;
obj.data.filter_sz = filter_sz;
obj.data.hf = hf;

%obj.data.CG_state = CG_state;
if exist('CG_state', 'var')
    obj.data.CG_state = CG_state;
end
if exist('sample_energy', 'var')
    obj.data.sample_energy = sample_energy;
end