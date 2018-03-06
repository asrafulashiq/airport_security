function f =  check_bad_flow(im_flow, thres)

f = false;
im_flow_g = rgb2gray(im_flow);

im_filtered = imgaussfilt(im_flow_g, 4);
im_tmp = im_filtered;

im_tmp(im_tmp < 5) = 0;
im_tmp = logical(im_tmp);
if sum(im_tmp(:)) > thres
    disp('BAD FLOW!!');
    f = true;
end

end