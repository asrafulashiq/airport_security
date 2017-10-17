function [R_dropping,people_seq] = a_peopletracking_same(im_c,R_dropping,people_seq)

%% region 1 extraction
im_r = im_c(R_dropping.r1(3):R_dropping.r1(4),R_dropping.r1(1):R_dropping.r1(2),:);
thres_low = 0.4;
thres_up = 1.5;
min_allowed_dis = 200;
%% Region 1 background subtraction based on chromatic value

im_r_hsv = rgb2hsv(im_r);
im_p_hsv = rgb2hsv(R_dropping.im_r1_p);

im_fore = abs(im_r_hsv(:,:,2)-im_p_hsv(:,:,2)) + abs(im_p_hsv(:,:,2) - im_r_hsv(:,:,2));
im_fore = uint8(im_fore*255);

im_filtered = imgaussfilt(im_fore, 6);
im_filtered(im_filtered < 50) = 0;
% close operation for the image
se = strel('disk',10);
im_closed = imclose(im_filtered,se);

im_binary = logical(im_closed); %extract people region

%% blob analysis

cpro_r1 = regionprops(im_binary,'Centroid','Area','Orientation','BoundingBox', 'ConvexImage'); % extract parameters


% R_dropping structure
r1_obj = R_dropping.r1_obj;
r1_cnt = R_dropping.r1_cnt;
r1_lb = R_dropping.r1_lb;
% the border of r1
% y=-0.1304x+450.1304-10 \
% y=0.0868x+402.7579-10  /
[row,~] = size(im2_b);
limit_area = 1000;
% detect entering
dis_enter = 130;
dis_enter_x = 60;
dis_exit_x=200;
dis_exit_y=420;
split_num_y = 3;
split_num_x = 5;
dis1=100;

% the number of person in region 1
pcnt_r1 = size(cpro_r1,1);

temp_r1 = [];

%filtered with area
%the minimum area of region that can be seen as an object
for i = 1:pcnt_r1
    if (cpro_r1(i).Area > limit_area)
        temp_r1 = [temp_r1; [cpro_r1(i).Centroid(1) cpro_r1(i).Centroid(2) cpro_r1(i).Area 0 i]];
    end
end

pcnt_r1 = size(temp_r1,1);%number of people in the region

if (pcnt_r1 ~= 0)
    
    if (r1_cnt ~= 0)
        
        r1_obj(:,5) = 0;   %clear the status of FOUND
        dis_r1 = []; % measure the distance between people in current frame and last frame
        for i = 1:r1_cnt
            for j = 1:pcnt_r1
                dis_r1(i,j) = sqrt((r1_obj(i,1)-temp_r1(j,1))^2 + (r1_obj(i,2)-temp_r1(j,2))^2);
            end
        end
        
        sort_t = [];
        sort_o = [];
        
        %sort the minimum distance
        for i = 1:r1_cnt
            sort_t(i) = find(dis_r1(i,:)==min(dis_r1(i,:)),1);
        end
        
        for i = 1:pcnt_r1
            sort_o(i)=find(dis_r1(:,i)==min(dis_r1(:,i)),1);
        end
        %% change distance here?
        p_dis_limit = 80;
        %p_dis_limit=120;
        for i = 1:r1_cnt
            % double match
            if (sort_o(sort_t(i))==i)
                r1_obj(i,1:2) = 0.5*temp_r1(sort_t(i),1:2)+0.5*r1_obj(i,1:2);
                r1_obj(i,3) = temp_r1(sort_t(i),3);
                r1_obj(i,5) = 1;
                temp_r1(sort_t(i),4) = 1;
                
            else
                ob_mat = find(sort_o==i);
                % object match
                if (~isempty(ob_mat))
                    ob_mat_sz = size(ob_mat,2);
                    if (ob_mat_sz==1)
                        if (dis_r1(i,ob_mat(1))<120) %distance constraint
                            r1_obj(i,1:2) = 0.5*temp_r1(ob_mat(1),1:2)+0.5*r1_obj(i,1:2);
                            r1_obj(i,3) = temp_r1(ob_mat(1),3);
                            r1_obj(i,5) = 1;
                            temp_r1(ob_mat(1),4) = 1;
                        end
                    else
                        mrg_ind = find(dis_r1(ob_mat,i)==min(dis_r1(ob_mat,i)));
                        r1_obj(i,1:2) = 0.5*temp_r1(mrg_ind,1:2)+0.5*r1_obj(i,1:2);
                        r1_obj(i,3) = temp_r1(mrg_ind,3);
                        r1_obj(i,5) = 1;
                        temp_r1(mrg_ind,4) = 1;
                    end
                    % more than one person to one object
                    
                elseif (dis_r1(i,sort_t(i)) < p_dis_limit)
                    p_merg = find(sort_t==sort_t(i));
                    
                    t_pro = cpro_r1(temp_r1(sort_t(i),5));
                    m_cnt = size(p_merg,2);
                    
                    if (m_cnt==2)
                        
                        km = i;
                        to_merg_ind = find(p_merg~=i,1);
                        merg_ind = p_merg(to_merg_ind);
                        
                        if (t_pro.Centroid(2)>0.4*row)&&(t_pro.Centroid(2)<0.6*row)
                            if(t_pro.Orientation>20)&&(t_pro.Orientation<70)
                                merge_p(1,:)=[t_pro.Centroid(1)+t_pro.BoundingBox(3)/split_num_x t_pro.Centroid(2)-t_pro.BoundingBox(4)/split_num_y];
                                merge_p(2,:)=[t_pro.Centroid(1)-t_pro.BoundingBox(3)/split_num_x t_pro.Centroid(2)+t_pro.BoundingBox(4)/split_num_y];
                            elseif (t_pro.Orientation>70)||(t_pro.Orientation<-70)
                                merge_p(1,:)=[t_pro.Centroid(1) t_pro.Centroid(2)-t_pro.BoundingBox(4)/split_num_y];
                                merge_p(2,:)=[t_pro.Centroid(1) t_pro.Centroid(2)+t_pro.BoundingBox(4)/split_num_y];
                            elseif (t_pro.Orientation<-20)&&(t_pro.Orientation>-70)
                                merge_p(1,:)=[t_pro.Centroid(1)-t_pro.BoundingBox(3)/split_num_x t_pro.Centroid(2)-t_pro.BoundingBox(4)/split_num_y];
                                merge_p(2,:)=[t_pro.Centroid(1)+t_pro.BoundingBox(3)/split_num_x t_pro.Centroid(2)+t_pro.BoundingBox(4)/split_num_y];
                            else
                                merge_p(1,:)=[t_pro.Centroid(1)-t_pro.BoundingBox(3)/split_num_x t_pro.Centroid(2)];
                                merge_p(2,:)=[t_pro.Centroid(1)+t_pro.BoundingBox(3)/split_num_x t_pro.Centroid(2)];
                            end
                        else
                            if(t_pro.Orientation>0)
                                merge_p(1,:)=[t_pro.Centroid(1)+t_pro.BoundingBox(3)/split_num_x t_pro.Centroid(2)-t_pro.BoundingBox(4)/split_num_y];
                                merge_p(2,:)=[t_pro.Centroid(1)-t_pro.BoundingBox(3)/split_num_x t_pro.Centroid(2)+t_pro.BoundingBox(4)/split_num_y];
                            else
                                merge_p(1,:)=[t_pro.Centroid(1)-t_pro.BoundingBox(3)/split_num_x t_pro.Centroid(2)-t_pro.BoundingBox(4)/split_num_y];
                                merge_p(2,:)=[t_pro.Centroid(1)+t_pro.BoundingBox(3)/split_num_x t_pro.Centroid(2)+t_pro.BoundingBox(4)/split_num_y];
                            end
                        end
                        merge_p = merge_p + [0 -10];
                        
                        r1_obj(km,3) = temp_r1(sort_t(km),3);
                        r1_obj(km,5) = 1;
                        temp_r1(sort_t(km),4) = 1;
                        
                        dis_mer(1) = sqrt((r1_obj(km,1)-merge_p(1,1))^2+(r1_obj(km,2)-merge_p(1,2))^2);
                        dis_mer(2) = sqrt((r1_obj(km,1)-merge_p(2,1))^2+(r1_obj(km,2)-merge_p(2,2))^2);
                        
                        if dis_mer(1)<dis_mer(2)
                            r1_obj(km,1:2) = merge_p(1,:);
                            r1_obj(merg_ind,1:2) = merge_p(2,:);
                        else
                            r1_obj(km,1:2) = merge_p(2,:);
                            r1_obj(merg_ind,1:2) = merge_p(1,:);
                        end
                        
                    end
                    
                end
            end
        end
        
        % detect exiting
        
        for i = 1:r1_cnt
            true_y=R_dropping.r1(3)+r1_obj(i,2);
            true_x=R_dropping.r1(1)+r1_obj(i,1);
            if (true_y>=dis_exit_y || true_y<(1.0e+03)*(0.0055*(true_x)-1.4730)+dis1)
                people_seq = [people_seq;r1_obj(i,:)];
                r1_obj(i:end-1,:) = r1_obj(i+1:end,:);
                r1_cnt = r1_cnt-1;
                r1_obj = r1_obj(1:r1_cnt,:);
                disp('delete!');
                break
            end
        end

        
        for i = 1:pcnt_r1
            if (temp_r1(i,4)==0)
                true_y=R_dropping.r1(3)+temp_r1(i,2);
                true_x=R_dropping.r1(1)+temp_r1(i,1);
                %the condition of determine where is the entrance
                if (true_y>=(1.0e+03)*(0.0055*(true_x)-1.4730)+dis1 && temp_r1(i,2)<dis_enter)
                %if ((temp_r1(i,1)>dis_enter_x) && (temp_r1(i,2)<dis_enter))
                    r1_cnt = r1_cnt + 1;
                    r1_lb = r1_lb + 1;
                    r1_obj = [r1_obj;temp_r1(i,1:3) r1_lb 1];
                    temp_r1(i,4) = 1;
                end
            end
        end
                
    else
        for i = 1:pcnt_r1
            %add only one object with the maximum area
            true_y=R_dropping.r1(3)+temp_r1(i,2);
            true_x=R_dropping.r1(1)+temp_r1(i,1);
            %the condition of determine where is the entrance
            if (true_y>=(1.0e+03)*(0.0055*(true_x)-1.4730)+dis1 && temp_r1(i,2)<dis_enter)
                r1_cnt = 1;
                r1_lb = r1_lb+1;
                r1_obj(1,:) = [temp_r1(find(temp_r1(:,3)==max(temp_r1(:,3))),1:3) r1_lb 1];
            end
        end
    end
end
R_dropping.r1_obj = r1_obj;
R_dropping.r1_cnt = r1_cnt;
R_dropping.r1_lb = r1_lb;

end