function [R_belt,im_color,bin_seq, bin_array] = a_solve_bin_bin_tracking_2(im2_b,im_c,R_dropping,R_belt,bin_seq, bin_array)

global debug;


r1_obj = R_dropping.r1_obj;
r1 = R_dropping.r1;
r4_obj = R_belt.r4_obj;
r4_cnt = R_belt.r4_cnt;
r4_lb = R_belt.r4_lb;
r4 = R_belt.r4;
im_r4_p = R_belt.im_r4_p;

r4_obj = [];

%% Set up parameters
%limit_area = 3000;%the minimum area of region that can be seen as an object
threshold = 10;%threshold for object recognition
%dis_enter = 150;%enter distance (coordinate x)
%dis_enter_y = 80;%enter dista nce (coordinate y)
%dis_exit = 185;%exit distance (coordinate row /x)
dis_exit_y = 240;
dis_exit_limit = 40;
%% Preprocessing
im_actual = im_c(r4(3):r4(4),r4(1):r4(2),:);

im_all = rgb2gray(im_actual);

%im_channel = rgb2gray(im_r4);
im_background = rgb2gray(im_r4_p);
im_r4 = 2 * abs(im_all-im_background);


%x = smoothdata(x);

% figure(2);plot(x);
% figure(3);imshow(im_r4);
% drawnow;

%imr4eqc = 0.33*(im_r4(:,:,1)+im_r4(:,:,2)+im_r4(:,:,3));

imr4t = im_r4;

pt2 = [];
stp2 = 10;

%stp1 = 20;
% for i = (1+stp1):(size(imr4t,1)-stp2)
%     pt2(i) = mean(mean(imr4t(i-stp2:i+stp2,:)));
% end

for i = 1: (size(imr4t,1)-stp2)
    pt2(i) = mean( mean( imr4t(i:i+stp2,:) ) );
end
%pt2_293x1 = medfilt1(reshape(pt2,[size(pt2,2) 1]),50);
% % figure(2);
% % plot(pt2_293x1);


%loc = find(pt2_293x1>threshold);

loc = find( pt2 > threshold);

if isempty(loc)
    im_color = im_c;
    return;
end

loc_something = [ loc(1) loc(end) ];

%im_all = rgb2gray(im_all);
% subtract background
% if ~isempty(bin_array)
%     x = [bin_array{1,:}];
%     x_cen = [x.Centroid];
%     x_cen_y = x_cen(2,:);
% end

% for i=1:size(im_all,1)
%     if isempty(find(loc==i, 1))
%         if  ~isempty(bin_array) && abs(min(x_cen_y-i)) < 40
%             continue;
%         else
%             im_all(i,:) = 0;
%         end
%     end
% end

% increase brightness
%im_all(loc,:) = imadjust(im_all(loc,:), [ 0; 0.6 ], [ 0.1; 0.8 ] );

I = im_all;

% bin_array = my_template_match_main(loc_something, I, bin_array , 0.8);

if debug
    figure(2);
    plot(1:size(im_r4,1), calc_intens(im_r4,[]));
    hold on;
end


bin_array = match_template_signal(im_r4, bin_array, loc_something);

if debug
    hold off;
    drawnow;
end

% im_color = im_c;
% return;


%% bin processing
total_bins = size(bin_array,2);
i = 1;
for counter = 1: total_bins
    
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
        r4_cnt=r4_cnt+1;
        
        bin_array{i}.belongs_to = belongs_to;
        bin_array{i}.label = r4_lb;
        
        i = i+1; % go to next bin in bin_array
        
        %%% detect exiting
    elseif bin_array{i}.Centroid(2) >= dis_exit_y  % || ...
        %             ( bin_array{i}.Centroid(2) >= dis_exit_y - dis_exit_limit ...
        %             && isempty( find( r1_obj(:,4) == bin_array{i}.belongs_to, 1 ))  )
        
        if abs(bin_array{i}.limit(2)-size(im_r4,1)) > 30
            
            if bin_array{i}.in_flag ~= 0
                r4_obj_this = [ bin_array{i}.Centroid(1)  bin_array{i}.Centroid(2)  bin_array{i}.Area ...
                    bin_array{i}.label  1  bin_array{i}.belongs_to  ];
                bin_seq = [ bin_seq; r4_obj_this  ];
                r4_cnt = r4_cnt - 1;
                bin_array{i}.in_flag = 0;
            end
            
            i = i + 1;
            
        else
            
            bin_array(i) = [];
            disp('delete');
            
        end
        
    else
        i = i+1;
    end
    
end

for i=1:size(bin_array,2)
    if bin_array{i}.in_flag==1
        bin = double([ bin_array{i}.Centroid(1) bin_array{i}.Centroid(2) bin_array{i}.Area ...
            bin_array{i}.label 1 bin_array{i}.belongs_to ]);
        r4_obj = [r4_obj; bin];
    end
end

im_color = im_c;
R_belt.r4_obj = r4_obj;
R_belt.r4_cnt = r4_cnt;
R_belt.r4_lb = r4_lb;
R_dropping.r1_obj = r1_obj;

end



