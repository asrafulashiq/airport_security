function im_c = displayimage11_13_bin(im_c, bin_array, camera_no)
global scale;
global k_distort_11;
global k_distort_13;

if camera_no == 11
    k_dist = k_distort_11;
else
    k_dist = k_distort_13;
end

%% decorate text
font_size_im = 40 * scale;
text_im=uint8(ones(size(im_c, 1), floor(size(im_c, 2) * 0.6), 3) * 255);

offsetx = 0;
offsety = 0;
%%% annotate main image
%% plot bin
if numel(bin_array) == 0
    im_c = uint8(zeros(size(im_c, 1), size(im_c, 2), 3));    
else
    for i=1:numel(bin_array)
        if bin_array{i}.in_flag==1
            
            bounding_box = [ bin_array{i}.BoundingBox(1) + 3*offsetx ...
                bin_array{i}.BoundingBox(2) + offsety...
                bin_array{i}.BoundingBox(3)-4*offsetx ...
                bin_array{i}.BoundingBox(4)-2*offsety ];
            
            im_c = insertShape(im_c, 'FilledRectangle', bounding_box, 'Color', 'red', ...
                'Opacity', 0.3);
            im_c = insertShape(im_c, 'Rectangle', bounding_box, 'LineWidth', 2, 'Color', 'red');
            if bin_array{i}.belongs_to ~= -1
                text_ = sprintf('bin:%d\nperson:%d',bin_array{i}.label, bin_array{i}.belongs_to);
            else
                text_ = sprintf('bin:%d',bin_array{i}.label);
                
            end
            im_c = insertText(im_c, bounding_box(1:2), text_, 'FontSize', font_size_im);
            
        end
    end
    
    im_c = lensdistort(im_c, -k_dist);
end

end