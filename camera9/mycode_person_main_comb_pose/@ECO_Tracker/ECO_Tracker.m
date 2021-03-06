classdef ECO_Tracker
    
    properties
        data
    end
    
    methods
        
        % constructor
        function obj = ECO_Tracker
            obj = obj.setPara();
        end
        
        % set parameters
        obj = setPara(obj)
        
        % tracker initialization
        obj = initTracker(obj, im, init_rect)
        
        % start Tracking
        [obj, rect_position_vis] = runTrack(obj, im)
        
        
    end
    
    methods(Static)
        %% helper methods
        [seq, init_image] = get_sequence_info(seq)
        
        params = init_default_params(params)
        
        feature_params = init_feature_params(features, feature_info)
        
        [features, gparams, feature_info] = init_features(features, gparams, is_color_image, img_sample_sz, size_mode)
        
        extract_info = get_feature_extract_info(features)
        
        [nScales, scale_step, scaleFactors, scale_filter, params] = init_scale_filter(params)
        
        feature_map = extract_features(image, pos, scales, features, gparams, extract_info)
        
        xf = interpolate_dft(xf, interp1_fs, interp2_fs)
        
        xf = compact_fourier_coeff(xf)
        
        xf = shift_sample(xf, shift, kx, ky)
        
        projection_matrix = init_projection_matrix(init_sample, compressed_dim, params)
        
        x = project_sample(x, P)
        
        [merged_sample, new_sample, merged_sample_id, new_sample_id, distance_matrix, gram_matrix, prior_weights] = ...
            update_sample_space_model_gpu(samplesf, new_train_sample, distance_matrix, gram_matrix, prior_weights,...
            num_training_samples,params)
        
        [prior_weights, replace_ind] = update_prior_weights(prior_weights, sample_weights, latest_ind, frame, params)
        
        [hf, projection_matrix, res_norms] = train_joint(hf, projection_matrix, xlf, yf, reg_filter, sample_energy, reg_energy, proj_energy, params, init_CG_opts)
        
        [hf, projection_matrix, res_norms] = train_joint_gpu(hf, projection_matrix, init_samplef, yf, reg_filter, sample_energy, reg_energy, proj_energy, params, init_CG_opts)
        
        [hf, res_norms, CG_state] = train_filter_gpu(hf, samplesf, yf, reg_filter, sample_weights, sample_energy, reg_energy, params, CG_opts, CG_state)
        
        [hf, res_norms, CG_state] = train_filter(hf, samplesf, yf, reg_filter, sample_weights, sample_energy, reg_energy, params, CG_opts, CG_state)
        
        xf = full_fourier_coeff(xf)
        
        scale_filter = scale_filter_update(im, pos, base_target_sz, currentScaleFactor, scale_filter, params)
        
        [disp_row, disp_col, scale_ind] = optimize_scores(scores_fs, iterations)
        
        scale_change_factor = scale_filter_track(im, pos, base_target_sz, currentScaleFactor, scale_filter, params)
        
        seq = report_tracking_result(seq, result)
        
        [interp1_fs, interp2_fs] = get_interp_fourier(sz, params)
        
    end
    
end