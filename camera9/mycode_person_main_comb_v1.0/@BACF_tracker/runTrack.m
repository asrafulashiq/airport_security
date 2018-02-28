function [obj, rect] = runTrack(obj, im)

%%
%   Setting parameters for local use.
params = obj.data.params;
search_area_scale   = params.search_area_scale;
output_sigma_factor = params.output_sigma_factor;
learning_rate       = params.learning_rate;
filter_max_area     = params.filter_max_area;
nScales             = params.number_of_scales;
scale_step          = params.scale_step;
interpolate_response = params.interpolate_response;

global_feat_params = params.t_global;
visualization  = params.visualization;
featureRatio = params.t_global.cell_size;
%num_frames     = params.no_fram;

%set the feature ratio to the feature-cell size

pos = obj.data.pos;
target_sz = obj.data.target_sz;
data.currentScaleFactor = obj.data.currentScaleFactor;
base_target_sz  = obj.data.base_target_sz;
sz = obj.data.sz;
use_sz= obj.data.use_sz;
y = obj.data.y;
yf = obj.data.yf;
interp_sz = obj.data.interp_sz;
cos_window = obj.data.cos_window;
features = obj.data.features;
scaleFactors = obj.data.scaleFactors;
min_scale_factor = obj.data.min_scale_factor;
max_scale_factor = obj.data.max_scale_factor;
ky = obj.data.ky;
kx = obj.data.kx;
newton_iterations = obj.data.newton_iterations;
%rect_position = obj.data.rect_position;
%time = obj.data.time;
multires_pixel_template = obj.data.multires_pixel_template;
small_filter_sz = obj.data.small_filter_sz;
loop_frame = obj.data.loop_frame;
currentScaleFactor = obj.data.currentScaleFactor;
if isfield(obj.data,'g_f')
g_f = obj.data.g_f;
end

%%
frame = obj.data.frame;

frame = frame + 1;

if frame > 1
    model_xf = obj.data.model_xf;
end

if frame > 1
    for scale_ind = 1:nScales
        multires_pixel_template(:,:,:,scale_ind) = ...
            get_pixels(im, pos, round(sz*currentScaleFactor*scaleFactors(scale_ind)), sz);
    end
    xtf = fft2(bsxfun(@times,get_features(multires_pixel_template,features,global_feat_params),cos_window));
    responsef = permute(sum(bsxfun(@times, conj(g_f), xtf), 3), [1 2 4 3]);
    
    % if we undersampled features, we want to interpolate the
    % response so it has the same size as the image patch
    if interpolate_response == 2
        % use dynamic interp size
        interp_sz = floor(size(y) * featureRatio * currentScaleFactor);
    end
    responsef_padded = resizeDFT2(responsef, interp_sz);
    
    % response in the spatial domain
    response = ifft2(responsef_padded, 'symmetric');
    
    % find maximum peak
    if interpolate_response == 3
        error('Invalid parameter value for interpolate_response');
    elseif interpolate_response == 4
        [disp_row, disp_col, sind] = resp_newton(response, responsef_padded, newton_iterations, ky, kx, use_sz);
    else
        [row, col, sind] = ind2sub(size(response), find(response == max(response(:)), 1));
        disp_row = mod(row - 1 + floor((interp_sz(1)-1)/2), interp_sz(1)) - floor((interp_sz(1)-1)/2);
        disp_col = mod(col - 1 + floor((interp_sz(2)-1)/2), interp_sz(2)) - floor((interp_sz(2)-1)/2);
    end
    % calculate translation
    switch interpolate_response
        case 0
            translation_vec = round([disp_row, disp_col] * featureRatio * currentScaleFactor * scaleFactors(sind));
        case 1
            translation_vec = round([disp_row, disp_col] * currentScaleFactor * scaleFactors(sind));
        case 2
            translation_vec = round([disp_row, disp_col] * scaleFactors(sind));
        case 3
            translation_vec = round([disp_row, disp_col] * featureRatio * currentScaleFactor * scaleFactors(sind));
        case 4
            translation_vec = round([disp_row, disp_col] * featureRatio * currentScaleFactor * scaleFactors(sind));
    end
    
    % set the scale
    currentScaleFactor = currentScaleFactor * scaleFactors(sind);
    % adjust to make sure we are not to large or to small
    if currentScaleFactor < min_scale_factor
        currentScaleFactor = min_scale_factor;
    elseif currentScaleFactor > max_scale_factor
        currentScaleFactor = max_scale_factor;
    end
    
    % update position
    old_pos = pos;
    pos = pos + translation_vec;
end

% extract training sample image region
pixels = get_pixels(im,pos,round(sz*currentScaleFactor),sz);

% extract features and do windowing
xf = fft2(bsxfun(@times,get_features(pixels,features,global_feat_params),cos_window));

if (frame == 1)
    model_xf = xf;
else
    model_xf = ((1 - learning_rate) * model_xf) + (learning_rate * xf);
end

g_f = single(zeros(size(xf)));
h_f = g_f;
l_f = g_f;
mu    = 1;
betha = 10;
mumax = 10000;
i = 1;

T = prod(use_sz);
S_xx = sum(conj(model_xf) .* model_xf, 3);
params.admm_iterations = 2;

while (i <= params.admm_iterations)
    %   solve for G- please refer to the paper for more details
    B = S_xx + (T * mu);
    S_lx = sum(conj(model_xf) .* l_f, 3);
    S_hx = sum(conj(model_xf) .* h_f, 3);
    g_f = (((1/(T*mu)) * bsxfun(@times, yf, model_xf)) - ((1/mu) * l_f) + h_f) - ...
        bsxfun(@rdivide,(((1/(T*mu)) * bsxfun(@times, model_xf, (S_xx .* yf))) - ((1/mu) * bsxfun(@times, model_xf, S_lx)) + (bsxfun(@times, model_xf, S_hx))), B);
    
    %   solve for H
    h = (T/((mu*T)+ params.admm_lambda))* ifft2((mu*g_f) + l_f);
    [sx,sy,h] = get_subwindow_no_window(h, floor(use_sz/2) , small_filter_sz);
    t = single(zeros(use_sz(1), use_sz(2), size(h,3)));
    t(sx,sy,:) = h;
    h_f = fft2(t);
    
    %   update L
    l_f = l_f + (mu * (g_f - h_f));
    
    %   update mu- betha = 10.
    mu = min(betha * mu, mumax);
    i = i+1;
end

target_sz = floor(base_target_sz * currentScaleFactor);

%save position and calculate FPS
%rect_position(loop_frame,:) = [pos([2,1]) - floor(target_sz([2,1])/2), target_sz([2,1])];

%time = time + toc();
rect_position_vis = [pos([2,1]) - target_sz([2,1])/2, target_sz([2,1])];
%visualization
if visualization == 1
    
    im_to_show = double(im)/255;
    if size(im_to_show,3) == 1
        im_to_show = repmat(im_to_show, [1 1 3]);
    end
    if frame == 1
        figure(1);
        imshow(im_to_show);
        hold on;
        rectangle('Position',rect_position_vis, 'EdgeColor','g', 'LineWidth',2);
        text(10, 10, int2str(frame), 'color', [0 1 1]);
        hold off;
        axis off;axis image;set(gca, 'Units', 'normalized', 'Position', [0 0 1 1])
    else
        resp_sz = round(sz*currentScaleFactor*scaleFactors(scale_ind));
        xs = floor(old_pos(2)) + (1:resp_sz(2)) - floor(resp_sz(2)/2);
        ys = floor(old_pos(1)) + (1:resp_sz(1)) - floor(resp_sz(1)/2);
        sc_ind = floor((nScales - 1)/2) + 1;
        
        figure(1);
        imshow(im_to_show);
        hold on;
        resp_handle = imagesc(xs, ys, fftshift(response(:,:,sc_ind))); colormap hsv;
        alpha(resp_handle, 0.2);
        rectangle('Position',rect_position_vis, 'EdgeColor','g', 'LineWidth',2);
        %text(20, 30, ['# Frame : ' int2str(loop_frame) ' / ' int2str(num_frames)], 'color', [1 0 0], 'BackgroundColor', [1 1 1], 'fontsize', 16);
        %text(20, 60, ['FPS : ' num2str(1/(time/loop_frame))], 'color', [1 0 0], 'BackgroundColor', [1 1 1], 'fontsize', 16);
        
        hold off;
    end
    drawnow
end

loop_frame = loop_frame + 1;
rect = rect_position_vis;

%%
if frame > 1
    obj.data.old_pos = old_pos;
end

obj.data.model_xf = model_xf; 


obj.data.pos = pos;
obj.data.currentScaleFactor = currentScaleFactor;
obj.data.interp_sz = interp_sz;
obj.data.target_sz = target_sz;
obj.data.loop_frame = loop_frame;
obj.data.frame = frame;

if exist('g_f')
   obj.data.g_f = g_f; 
end

end