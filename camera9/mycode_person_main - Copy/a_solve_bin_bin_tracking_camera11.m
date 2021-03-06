function [bin_seq, bin_array, R_belt] = a_solve_bin_bin_tracking_camera11(im_c,R_dropping,R_belt,bin_seq, bin_array, people_array, R_c9)

global debug;
global scale;
global associate;
%global k_distort;

r4 = R_belt.r4;
im_r4_p = R_belt.im_r4_p;

%% Set up parameters
threshold = 13; %threshold for object recognition
dis_exit_y = 900 * scale;

%% Preprocessing
im_actual = im_c(r4(3):r4(4),r4(1):r4(2),:);

im_all = rgb2gray(im_actual);
im_background = rgb2gray(im_r4_p);
%im_r4 = 2 * abs(im_all-im_background);

% im_r4 = uint8(abs(im_actual - im_r4_p));
im_r4 = abs(im_r4_p - im_actual) + abs(im_actual - im_r4_p);
im_r4 = rgb2gray(im_r4);
%im_r4 = lensdistort(im_r4, k_distort);

imr4t = im_r4;

pt2 = [];
stp2 = 10;

for i = 1: (size(imr4t,1))
    pt2(i) = ( mean( imr4t(i,:) ) );
end

loc = find( pt2 > threshold);
if isempty(loc)
    
    if debug
        I = im_actual;
        figure(3); imshow(I);
        drawnow;
    end
    return;
end

loc_something = [ loc(1) loc(end) ];



I = uint8(zeros(size(im_actual,1), size(im_actual,2)));
I(loc,:) = rgb2gray(im_actual(loc,:,:));

%I = im_r4;
if debug
    figure(2);
    plot(1:size(I,1), calc_intens(I,[]));
    hold on;
end


[bin_array, R_belt] = match_template_signal_camera11(I, bin_array, loc_something, R_belt,R_c9, 1);

if debug
    hold off;
    drawnow;
end

%% bin processing
total_bins = size(bin_array,2);
i = 1;

limit_max_dist = 350 * scale;

for counter = 1: total_bins
    
%     if isfield(bin_array{i},'destroy')
%         bin_array(i) = [];
%         r4_cnt = r4_cnt - 1;
%         continue;
%     end
    
    if debug
        I = insertShape(I, 'Rectangle', bin_array{i}.BoundingBox, 'LineWidth', 3, 'Color', 'red');
    end
    
    %bin_array{i}.belongs_to = 1;
    
    %%% detect new bin and assign person
    if bin_array{i}.belongs_to == -1 % if no person is assigned
        centroid = bin_array{i}.Centroid;
        centroid = centroid';
        
        if centroid(2) > dis_exit_y
            bin_array(i) = [];
            continue;
        end
        
        r1_edge = [];
        
        for j = 1:size(people_array, 2)
            centr = double([people_array{j}.BoundingBox(1) people_array{j}.Centroid(2)]) ...
                + [R_dropping.r1(1) R_dropping.r1(3)];
            r1_edge = [r1_edge; centr];
        end
        
        if bin_array{i}.label == -1
            bin_array{i}.label = R_belt.label;
            R_belt.label = R_belt.label + 1;
        end
        
        if bin_array{i}.belongs_to == -1
            if ~isempty(people_array)
                dis_b_p = pdist2( r1_edge, double(centroid) + [R_belt.r4(1) R_belt.r4(3)]);
                bin_belong_index =  dis_b_p == min(dis_b_p);
                if min(dis_b_p) > limit_max_dist
                    belongs_to = -1;
                else
                    belongs_to = people_array{bin_belong_index}.id;
                    % check matching
                    intended_bin = [];
                    % find associated previous bin
                    for counter_i = 1:numel(R_c9.bin_seq)
                        if R_c9.bin_seq{counter_i}.label == bin_array{i}.label
                            intended_bin = R_c9.bin_seq{counter_i};
                            break;
                        end
                    end
                    if ~isempty(intended_bin)
                        to_match = intended_bin.belongs_to;
                    end
                    if ~isempty(intended_bin) && to_match == belongs_to
                        bin_array{i}.match = "right";
                    else
                        bin_array{i}.match = "wrong";
                    end
                end
            else
                belongs_to = -1;
            end
            bin_array{i}.belongs_to = belongs_to;
        end
          
        if debug
            bin_array{i}.belongs_to = 1;
        end
        
        i = i+1; % go to next bin in bin_array
        
        %%% detect exiting
    elseif bin_array{i}.Centroid(2) >= dis_exit_y
        %         if abs(bin_array{i}.limit(2)-size(im_r4,1)) > 30
        %             if bin_array{i}.in_flag ~= 0
        %                 bin_array{i}.in_flag = 0;
        %                 bin_seq{end+1} = bin_array{i};
        %             end
        %             i = i + 1;
        %         else
        if bin_array{i}.in_flag ~= 0
            bin_seq{end+1} = bin_array{i};
        end
        bin_array(i) = [];
        disp('delete');
        %         end
    else
        i = i+1;
    end
end

if debug
    figure(3); imshow(I);
    drawnow;
end

end



