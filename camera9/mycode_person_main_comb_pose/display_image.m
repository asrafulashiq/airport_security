function img = display_image(im_c, R_9, nfig)

global scale;

%% decorate text
font_size_im = 30 * scale;

%% bin
%im_c = im_c(R_9.R_bin.reg(3):R_9.R_bin.reg(4),R_9.R_bin.reg(1):R_9.R_bin.reg(2),:); % bin region
color_arr = {'blue', 'green', 'cyan', 'magenta', 'black'};

bin_array = R_9.R_bin.bin_array;

for i = 1:numel(bin_array)
    bounding_box = [ bin_array{i}.BoundingBox(1) + R_9.R_bin.reg(1) ...
        bin_array{i}.BoundingBox(2) + R_9.R_bin.reg(3) ...
        bin_array{i}.BoundingBox(3) ...
        bin_array{i}.BoundingBox(4) ];
    
    if bin_array{i}.belongs_to ~= -1
      color = color_arr(bin_array{i}.belongs_to);
   else
       color = 'red';
   end
    
    im_c = insertShape(im_c, 'FilledRectangle', bounding_box, 'Color', color, 'opacity', 0.2);
    im_c = insertShape(im_c, 'Rectangle', bounding_box, 'LineWidth', 3, 'Color', color);
    text_ = sprintf('bin:%d', bin_array{i}.label);
    im_c = insertText(im_c, bounding_box(1:2), text_, 'FontSize', font_size_im);
    
    if bin_array{i}.belongs_to ~= -1
        text_ = sprintf('person:%d', bin_array{i}.belongs_to);
        im_c = insertText(im_c, bounding_box(1:2)+[0 40], text_, 'FontSize', font_size_im);        
    end   
    %if bin_array{i}.state=="full"
        text_ = char(sprintf("state:%s", bin_array{i}.state));
        im_c = insertText(im_c, bounding_box(1:2)+[0 80], text_, 'FontSize', font_size_im);        
    %end
end

%% people
%im_c = im_c(R_9.R_people.reg(3):R_9.R_people.reg(4),R_9.R_people.reg(1):R_9.R_people.reg(2),:); % people region

people_array = R_9.R_people.people_array;

for i = 1:size(people_array, 2)
    bounding_box = [ people_array{i}.BoundingBox(1) + R_9.R_people.reg(1) ...
        people_array{i}.BoundingBox(2) + R_9.R_people.reg(3) ...
        people_array{i}.BoundingBox(3) ...
        people_array{i}.BoundingBox(4) ];
    
     color = color_arr(people_array{i}.label);

    
    im_c = insertShape(im_c, 'FilledRectangle', bounding_box, 'Color', color, 'opacity', 0.2);
    im_c = insertShape(im_c, 'Rectangle', bounding_box, 'LineWidth', 3, 'Color', color);
    text_ = sprintf('person:%d', people_array{i}.label);
    im_c = insertText(im_c, bounding_box(1:2), text_, 'FontSize', font_size_im);
    
end

if nargin > 2 &&  nfig > 0
    figure(nfig);
    imshow(im_c);
    title(sprintf('%04d',R_9.current_frame));
    drawnow;
end

img = im_c;

end