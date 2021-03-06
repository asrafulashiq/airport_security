function [R_belt,im_color,bin_seq, bin_array] = a_solve_bin_bin_tracking_2(im2_b,im_c,R_dropping,R_belt,bin_seq, bin_array)
r1_obj = R_dropping.r1_obj;
r1 = R_dropping.r1;
r4_obj = R_belt.r4_obj;
r4_cnt = R_belt.r4_cnt;
r4_lb = R_belt.r4_lb;
r4 = R_belt.r4;
im_r4_p = R_belt.im_r4_p;

r4_obj = [];

%% Set up parameters
limit_area = 3000;%the minimum area of region that can be seen as an object
threshold = 10;%threshold for object recognition
dis_enter = 150;%enter distance (coordinate x)
dis_enter_y = 80;%enter dista nce (coordinate y)
dis_exit = 185;%exit distance (coordinate row /x)
dis_exit_y = 220;
dis_exit_limit = 40;
%% Preprocessing
im_actual = im_c(r4(3):r4(4),r4(1):r4(2),:);

im_all = rgb2gray(im_actual);

%im_channel = rgb2gray(im_r4);
im_background = rgb2gray(im_r4_p);
im_r4 = 2 * abs(im_all-im_background);

x = [];
for i = 1:size(im_r4,1)
    x = [x mean(im_r4(i,:))];
end
[b,a] = butter(10,0.2);
x = filter(b,a,x);
%x = smoothdata(x);

figure(2);plot(x);
figure(3);imshow(im_r4);
drawnow;

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

loc_something = [ loc(1) loc(end)];

%im_all = rgb2gray(im_all);
% subtract background
if ~isempty(bin_array)
    x = [bin_array{1,:}];
    x_cen = [x.Centroid];
    x_cen_y = x_cen(2,:);
end

for i=1:size(im_all,1)
    if isempty(find(loc==i, 1)) 
        if  ~isempty(bin_array) && abs(min(x_cen_y-i)) < 40
            continue;
        else
            im_all(i,:) = 0;
        end
    end
end

% increase brightness
%im_all(loc,:) = imadjust(im_all(loc,:), [ 0; 0.6 ], [ 0.1; 0.8 ] );

I = im_all;

bin_array = my_template_match_main(loc_something, I, bin_array , 0.8);


%% for test
% cpro_r4 = [];
% template = {};

% 
% for i = 1:size(bin_array,2)
%     cpro_r4 = [cpro_r4;  struct('Area',bin_array{i}.Area, 'Centroid', bin_array{i}.Centroid, ...
%         'BoundingBox', bin_array{i}.BoundingBox ) ];
%     
%     template{end+1} =  struct( ...
%         'image',bin_array{i}.image, ...
%         'BoundingBox', bin_array{i}.BoundingBox ...
%         ) ;
%     
% end

%% draw conveyar
% figure(2);
% imshow(im_channel);
%
% figure(3);
% len = size(template,2);
% for i=1:len
%   subplot(len,1,i);
%   imshow(template{i}.image);
% end
% drawnow;
%%

% filtered with area;
% temp_r4 = [];
% for i = 1:size(cpro_r4,1)
%     if (cpro_r4(i).Area>limit_area)
%         temp_r4 = [temp_r4; ...
%             double([cpro_r4(i).Centroid(1) cpro_r4(i).Centroid(2) cpro_r4(i).Area 0 i]) ];
%     end
% end

%pcnt_r4 = size(bin_array,2);



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
     elseif bin_array{i}.Centroid(2) >= dis_exit_y || ...       
        ( bin_array{i}.Centroid(2) >= dis_exit_y - dis_exit_limit ...
         && isempty( find( r1_obj(:,4) == bin_array{i}.belongs_to, 1 ))  )
        
            r4_obj_this = [ bin_array{i}.Centroid(1)  bin_array{i}.Centroid(2)  bin_array{i}.Area ...
                bin_array{i}.label  1  bin_array{i}.belongs_to  ];
            bin_seq = [ bin_seq; r4_obj_this  ];
            r4_cnt = r4_cnt-1;
            disp('delete');
            
            bin_array(i) = [];
    else
        i = i+1;
    end
            
end



%%
% if (pcnt_r4~=0)
%     
%     if (r4_cnt ~= 0)
%         
% %         r4_obj(:,5) = 0;   %clear the status of FOUND
% %         dis_r4 = [];
% %         dis_bin = 100*ones(r4_cnt,r4_cnt);
% %         for i = 1:r4_cnt
% %             for j = 1:pcnt_r4
% %                 dis_r4(i,j) = sqrt((r4_obj(i,1)-temp_r4(j,1))^2+(r4_obj(i,2)-temp_r4(j,2))^2);
% %             end
% %         end
% %         
% %         sort_prev = [];
% %         sort_now = [];
% %         
% %         %sort the minimum distance
% %         for i = 1:r4_cnt
% %             sort_prev(i) = find(dis_r4(i,:)==min(dis_r4(i,:)),1);
% %         end
% %         for i = 1:pcnt_r4
% %             sort_now(i) = find(dis_r4(:,i)==min(dis_r4(:,i)),1);
% %         end
% %         
% %         %%%%%%%%%
% %         % double match?
% %         for i = 1:r4_cnt
% %             if (sort_now(sort_prev(i))==i && abs(temp_r4(sort_prev(i),2)-r4_obj(i,2))<50)
% %                 r4_obj(i,1:2) = 0.5*temp_r4(sort_prev(i),1:2)+0.5*r4_obj(i,1:2);
% %                 r4_obj(i,3) = temp_r4(sort_prev(i),3);
% %                 r4_obj(i,5) = 1;
% %                 temp_r4(sort_prev(i),4) = 1;
% %             end
% %         end
% %         
% %         
% %         % check the distance between two bins
% %         for i = 1:r4_cnt
% %             if (i+1) <= r4_cnt
% %                 dis_bin(i+1:r4_cnt,i) = sqrt((r4_obj(i+1:r4_cnt,1)-r4_obj(i,1)).^2 ...
% %                     +(r4_obj(i+1:r4_cnt,2)-r4_obj(i,2)).^2);
% %             end
% %         end
% %         
% %         %% push the bins ahead if they are neighbors
% %         for i = 1:r4_cnt
% %             min_dis_bin=min([min(dis_bin(:,i)) min(dis_bin(i,:))]);
% %             if min_dis_bin<=40
% %                 [m_a, m_b]=find(dis_bin==min_dis_bin(1,1));
% %                 if(m_a==i)
% %                     idx=m_b;
% %                 else
% %                     idx=m_a;
% %                 end
% %                 if (r4_obj(i,2)>100 && r4_obj(i,2)>r4_obj(idx,2))
% %                     r4_obj(i,2)=r4_obj(i,2)+10;
% %                 end
% %             end
% %         end
%         
%         %detect entering
%         for i = 1:pcnt_r4
%             
%             if (temp_r4(i,4)==0)
%                 if (temp_r4(i,2)<dis_enter && temp_r4(i,1)<dis_enter_y)
%                     
%                     dis1 = pdist2(r4_obj(:,1:2),temp_r4(i,1:2),'euclidean');
%                     if min(dis1)>=50
%                         %py1=max(1,round(temp_r4(i,2)-35));
%                         %py2=min(R_belt.r4(4)-R_belt.r4(3),round(temp_r4(i,2)+35));
%                         % double check if there is a people nearby
%                         max_dist_b_p=72;
%                         r1_edge=r1_obj(:,1:2)+[R_dropping.r1(1) R_dropping.r1(3)];
%                         r1_edge(:,1)=r1_edge(:,1)-sqrt(r1_obj(:,3));
%                         r1_edge(r1_edge(:,1)<R_dropping.r1(1),1)=R_dropping.r1(1);
%                         dist_b_p=pdist2(r1_edge,temp_r4(i,1:2)+[R_belt.r4(1) R_belt.r4(3)],'euclidean');
%                         dist_b_p_min=min(dist_b_p);
%                         if dist_b_p_min>max_dist_b_p
%                             continue;
%                         end
%                         r4_cnt=r4_cnt+1;
%                         %% find out whose bin is put on the belt
%                         r4_lb=r4_lb+1;
%                         bin_belong=find(dist_b_p==dist_b_p_min);
%                         r4_obj=[r4_obj;temp_r4(i,1:3) r4_lb 1 r1_obj(bin_belong(1,1),4)];
%                         %save the detected bin
%                         %save_bin_path='../detected_bin/';
%                         %px = temp_r4(i,1)+R_belt.r4(1);
%                         %py = temp_r4(i,2)+R_belt.r4(3);
%                         %wintx = 35;
%                         %winty = 25;
%                         %imwrite(im_c(py-winty:py+winty,px-wintx:px+wintx),...
%                         %    [save_bin_path 'b' num2str(r4_lb) ' p' num2str(r1_obj(bin_belong(1,1),4)) '.jpg'])
%                     end
%                 end
%             end
%         end
%         
%         %detect exiting
%         for i = 1:r4_cnt
%             if (r4_obj(i,2)>=dis_exit)
%                 bin_seq = [bin_seq;r4_obj(i,:)];
%                 r4_obj(i:end-1,:) = r4_obj(i+1:end,:);
%                 r4_cnt = r4_cnt-1;
%                 r4_obj = r4_obj(1:r4_cnt,:);
%                 disp('delete!');
%                 break
%             elseif (r4_obj(i,2)>=(dis_exit-40) && isempty(find(r1_obj(:,4)==r4_obj(i,6), 1)))
%                 bin_seq = [bin_seq;r4_obj(i,:)];
%                 r4_obj(i:end-1,:) = r4_obj(i+1:end,:);
%                 r4_cnt = r4_cnt-1;
%                 r4_obj = r4_obj(1:r4_cnt,:);
%                 disp('delete!');
%                 break
%             end
%             
%         end
%         
%         
%     else %r4_cnt == 0
%         
%         for q = 1:pcnt_r4
%             if (temp_r4(q,2)<dis_enter && temp_r4(q,1)<dis_enter_y && temp_r4(q,3)>limit_area)
%                 %find the maximum area of the temp region
%                 %py1=max(1,round(temp_r4(q,2)-35));
%                 %py2=min(size(im_channel,1),round(temp_r4(q,2)+35));
%                 % double check if there is a people nearby
%                 max_dist_b_p=72;
%                 if size(r1_obj,1)==0
%                     continue;
%                 end
%                 r1_edge=r1_obj(:,1:2)+[R_dropping.r1(1) R_dropping.r1(3)];
%                 r1_edge(:,1)=r1_edge(:,1)-sqrt(r1_obj(:,3));
%                 r1_edge(r1_edge(:,1)<R_dropping.r1(1),1)=R_dropping.r1(1);
%                 dist_b_p=pdist2(r1_edge,temp_r4(q,1:2)+[R_belt.r4(1) R_belt.r4(3)],'euclidean');
%                 dist_b_p_min=min(dist_b_p);
%                 if dist_b_p_min>max_dist_b_p
%                     continue;
%                 end
%                 r4_cnt=r4_cnt+1;
%                 %% find out whose bin is put on the belt
%                 bin_belong=find(dist_b_p==dist_b_p_min);
%                 r4_lb=r4_lb+1;
%                 r4_obj=[r4_obj;temp_r4(q,1:3) r4_lb 1 r1_obj(bin_belong(1,1),4)];
%                 %save the detected bin
%                 %                 save_bin_path='./detected_bin/';
%                 %                 px = temp_r4(q,1)+R_belt.r4(1);
%                 %                 py = temp_r4(q,2)+R_belt.r4(3);
%                 %                 wintx = 35;
%                 %                 winty = 25;
%                 %                 imwrite(im_c(py-winty:py+winty,px-wintx:px+wintx),...
%                 %                     [save_bin_path 'b' num2str(r4_lb) ' p' num2str(r1_obj(bin_belong(1,1),4)) '.jpg'])
%             end
%         end
%     end
% end


for i=1:size(bin_array,2)
    bin = double([ bin_array{i}.Centroid(1) bin_array{i}.Centroid(2) bin_array{i}.Area ...
        bin_array{i}.label 1 bin_array{i}.belongs_to ]);
    r4_obj = [r4_obj; bin];
end

im_color = im_c;
R_belt.r4_obj = r4_obj;
R_belt.r4_cnt = r4_cnt;
R_belt.r4_lb = r4_lb;
R_dropping.r1_obj = r1_obj;

end



%
% imr4t(pt2_293x1>threshold,:) = 1;
% imr4t(pt2_293x1<=threshold,:) = 0;
% imr4t(1:stp1,:) = 0;
% imr4t(size(imr4t,1)-stp2:end,:) = 0;
% lb_r4 = bwlabel(imr4t);
% cpro_r4 = regionprops(lb_r4,'Centroid','Area','BoundingBox');
% %% add some color to the foreground it detected
% [row_max, col_max] = size(im_c);
% %result for region 1
% [row1,col1] = size(im2_b);
% for i = 1:row1
%     for j = 1:col1
%         if (im2_b(i,j)==1 && i+r1(3)<=row_max && j+r1(1)<=col_max)
%             im_c(i+r1(3),j+r1(1),1) = 219;
%         end
%     end
% end
%
% [row4,col4] = size(imr4t);
% for i = 1:row4
%     for j = 1:col4
%         if (imr4t(i,j)>0 && i+r4(3)<=row_max && j+r4(1)<=col_max)
%             im_c(i+r4(3),j+r4(1),ch) = 219;
%         end
%     end
% end



