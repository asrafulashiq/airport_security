function [bin_seq, bin_array] = a_solve_bin_bin_tracking_2(im_c,R_dropping,R_belt,bin_seq, bin_array, people_array)

global debug;
global scale;

r4_lb = R_belt.r4_lb;
r4 = R_belt.r4;
im_r4_p = R_belt.im_r4_p;

%% Set up parameters
threshold = 20;%threshold for object recognition
dis_exit_y = 980 * scale;%2401520;

%% Preprocessing
im_actual = im_c(r4(3):r4(4),r4(1):r4(2),:);

im_all = rgb2gray(im_actual);
im_background = rgb2gray(im_r4_p);
%im_r4 = 2 * abs(im_all-im_background);

% im_r4 = uint8(abs(im_actual - im_r4_p));
im_r4 = abs(im_r4_p - im_actual) + abs(im_actual - im_r4_p);
im_r4 = rgb2gray(im_r4);

imr4t = im_r4;

pt2 = [];
stp2 = 10;

for i = 1: (size(imr4t,1)-stp2)
    pt2(i) = mean( mean( imr4t(i:i+stp2,:) ) );
end

loc = find( pt2 > threshold);
if isempty(loc)
    return;
end

loc_something = [ loc(1) loc(end) ];

if debug
    figure(2);
    plot(1:size(im_r4,1), calc_intens(im_r4,[]));
    hold on;
end

I = uint8(zeros(size(im_actual,1), size(im_actual,2)));
I(loc,:) = rgb2gray(im_actual(loc,:,:));

bin_array = match_template_signal(I, bin_array, loc_something);

if debug
    hold off;
    drawnow;
end




%% bin processing
total_bins = size(bin_array,2);
i = 1;
for counter = 1: total_bins
    
    if isfield(bin_array{i},'destroy')
       bin_array(i) = [];
       %r4_cnt = r4_cnt - 1;
       continue;
    end
    
    bin_array{i}.belongs_to = 1;
    
    %%% detect new bin and assign person
    if bin_array{i}.belongs_to == -1 % if no person is assigned
        centroid = bin_array{i}.Centroid;
        centroid = centroid';
        
        if centroid(2) > dis_exit_y
            bin_array(i) = [];
            continue;
        end
        
        r1_edge=r1_obj(:,1:2)+[R_dropping.r1(1) R_dropping.r1(3)];
        r1_edge(:,1)=r1_edge(:,1)-sqrt(r1_obj(:,3));
        r1_edge(r1_edge(:,1)<R_dropping.r1(1),1)=R_dropping.r1(1);
        dis_b_p = pdist2( r1_edge, double(centroid) + [R_belt.r4(1) R_belt.r4(3)],'euclidean');
        bin_belong = find( dis_b_p == min(dis_b_p) );
        belongs_to = r1_obj(bin_belong(1,1),4);
        
        r4_lb=r4_lb+1;
        %r4_cnt=r4_cnt+1;
        
        bin_array{i}.belongs_to = belongs_to;
        bin_array{i}.label = r4_lb;
        
        i = i+1; % go to next bin in bin_array
        
        %%% detect exiting
    elseif bin_array{i}.Centroid(2) >= dis_exit_y  
        
        if abs(bin_array{i}.limit(2)-size(im_r4,1)) > 30
            
            if bin_array{i}.in_flag ~= 0
%                 r4_obj_this = [ bin_array{i}.Centroid(1)  bin_array{i}.Centroid(2)  bin_array{i}.Area ...
%                     bin_array{i}.label  1  bin_array{i}.belongs_to  ];
%                 bin_seq = [ bin_seq; r4_obj_this  ];
                bin_array{i}.in_flag = 0;
                bin_seq{end+1} = bin_array{i};
            end
            
            i = i + 1;
            
        else
            if bin_array{i}.in_flag ~= 0

                bin_seq{end+1} = bin_array{i};
            end
            bin_array(i) = [];
            disp('delete');
            
        end
        
    else
        i = i+1;
    end
    
end

% r4_obj = [];
% for i=1:size(bin_array,2)
%     if bin_array{i}.in_flag==1
%         bin = double([ bin_array{i}.Centroid(1) bin_array{i}.Centroid(2) bin_array{i}.Area ...
%             bin_array{i}.label 1 bin_array{i}.belongs_to ]);
%         r4_obj = [r4_obj; bin];
%     end
% end

% if r4_cnt ~= size(r4_obj,1)
%     r4_cnt = size(r4_obj,1);
%    %error('smething is wrong'); 
% end
% 
% im_color = im_c;
% R_belt.r4_obj = r4_obj;
% R_belt.r4_cnt = r4_cnt;
% R_belt.r4_lb = r4_lb;
% R_dropping.r1_obj = r1_obj;

end



