function dec = detect_bad_flow(im_flow, thres)

im_flow_g = rgb2gray(im_flow);

im_filtered = imgaussfilt(im_flow_g, 6);

im_filtered(im_filtered < 10) = 0;
im_filtered = logical(im_filtered);
if sum(im_filtered(:)) > thres
    disp('BAD FLOW!!!');
    dec = false;
    return;
end

dec =true;

end