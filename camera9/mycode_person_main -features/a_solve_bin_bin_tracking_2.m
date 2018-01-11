function [R_bin] = a_solve_bin_bin_tracking_2(im_c,R_people,R_bin)

global debug;
global scale;

r4_lb = R_bin.label;
r4 = R_bin.r4;
im_r4_p = R_bin.im_r4_p;

%% Set up parameters
threshold = 15; %threshold for object recognition
dis_exit_y = 1000 * scale;%2401520;
if scale == 0.5
    dis_exit_y = 480;
end

%% Preprocessing
im_actual = im_c(r4(3):r4(4),r4(1):r4(2),:);
im_actual_rgb = im_actual;

im_all = rgb2gray(im_actual);
im_background = rgb2gray(im_r4_p);
im_r4 = abs(im_all-im_background) + abs(im_background - im_all);

% im_r4 = uint8(abs(im_actual - im_r4_p));
%im_r4 = abs(im_r4_p - im_actual) + abs(im_actual - im_r4_p);
%im_r4 = rgb2gray(im_r4);

imr4t = im_r4;

pt2 = [];
stp2 = 10;

% for i = 1: (size(imr4t,1)-stp2)
%     pt2(i) = mean( mean( imr4t(i:i+stp2,:) ) );
% end

for i = 1: (size(imr4t,1))
    pt2(i) = ( mean( imr4t(i,:) ) );
end

loc = find( pt2 > threshold);
if isempty(loc)
    return;
end

loc_something = [ loc(1) loc(end) ];

I = uint8(zeros(size(im_actual,1), size(im_actual,2)));
I(loc,:) = rgb2gray(im_actual(loc,:,:));

%I = im_r4;

if debug
    figure(2);
    plot(1:size(I,1), calc_intens(I(:, 1:int32(size(I,2)/2)),[]), 'k', 'LineWidth', 1);
    hold on;
end

[R_bin] = match_template_signal_half(I, loc_something, R_bin, 1, im_actual_rgb);

if debug
    hold off;
    %drawnow;
    
end

%% bin processing
total_bins = size(R_bin.bin_array,2);
i = 1;

limit_max_dist = 280*scale;

for counter = 1: total_bins
    
    if isfield(R_bin.bin_array{i},'destroy') && R_bin.bin_array{i}.destroy == true
        R_bin.bin_array(i) = [];
        %r4_cnt = r4_cnt - 1;
        continue;
    end
    
    if debug
        im_actual = insertShape(im_actual, 'Rectangle', ...
            R_bin.bin_array{i}.BoundingBox, 'LineWidth', 5, 'Color', 'red' );        
    end
    
    %R_bin.bin_array{i}.belongs_to = 1;
    %%% detect new bin and assign person
    if R_bin.bin_array{i}.belongs_to == -1 % if no person is assigned
        centroid = R_bin.bin_array{i}.Centroid;
        centroid = centroid';
        
        if centroid(2) > dis_exit_y
            R_bin.bin_seq{end+1} = R_bin.bin_array{i};
            R_bin.bin_array(i) = [];
            continue;
        end
        
        r1_edge = [];
        
        for j = 1:size(R_people.people_array, 2)
            centr = double([R_people.people_array{j}.BoundingBox(1) R_people.people_array{j}.Centroid(2)])  + double([R_people.r1(1) R_people.r1(3)]);
            r1_edge = [r1_edge; centr];
        end
        
        if ~isempty(R_people.people_array) && R_bin.bin_array{i}.count >= 20
            
            last_people = R_people.people_array{end};
            dist_to_last = pdist2( double([R_people.people_array{end}.BoundingBox(1) R_people.people_array{end}.Centroid(2)])  + double([R_people.r1(1) R_people.r1(3)]), ...
                double(centroid) + [R_bin.r4(1) R_bin.r4(3)]);
            if dist_to_last <= limit_max_dist
                belongs_to = R_people.people_array{end}.label;
            else
                
                dis_b_p = pdist2( r1_edge, double(centroid) + [R_bin.r4(1) R_bin.r4(3)]);
                bin_belong_index =  dis_b_p == min(dis_b_p);
                if min(dis_b_p) > limit_max_dist
                    belongs_to = -1;
                else
                    belongs_to = R_people.people_array{bin_belong_index}.label;
                end
            end
        else
            belongs_to = -1;
        end
        
        R_bin.bin_array{i}.belongs_to = belongs_to;
        
        if R_bin.bin_array{i}.label == -1
            R_bin.bin_array{i}.label = R_bin.label;
            R_bin.label = R_bin.label + 1;
        end
        
        
        if debug
            R_bin.bin_array{i}.belongs_to = 1;
        end
        
        i = i+1; % go to next bin in R_bin.bin_array
        
        %%% detect exiting
    elseif R_bin.bin_array{i}.Centroid(2) >= dis_exit_y
        if abs(R_bin.bin_array{i}.limit(2)-size(im_r4,1)) > 30
            if R_bin.bin_array{i}.in_flag ~= 0
                R_bin.bin_array{i}.in_flag = 0;
                R_bin.bin_seq{end+1} = R_bin.bin_array{i};
            end
            i = i + 1;
        else
            if R_bin.bin_array{i}.in_flag ~= 0
                R_bin.bin_seq{end+1} = R_bin.bin_array{i};
            end
            R_bin.bin_array(i) = [];
            disp('delete');
        end
    else
        i = i+1;
    end
    
    
    
end

if debug
   
    figure(3);
    imshow(im_actual);
    
    if ~isempty(R_bin.flow)
        hold on;
        plot(R_bin.flow,'DecimationFactor',[5 5],'ScaleFactor',5);
        hold off;
    end

    drawnow;
    
end


end



