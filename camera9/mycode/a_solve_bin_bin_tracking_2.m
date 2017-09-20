function [R_belt,im_color,bin_seq, template] = a_solve_bin_bin_tracking_2(im2_b,im_c,R_dropping,R_belt,bin_seq, template)
r1_obj = R_dropping.r1_obj;
r1 = R_dropping.r1;
r4_obj = R_belt.r4_obj;
r4_cnt = R_belt.r4_cnt;
r4_lb = R_belt.r4_lb;
r4 = R_belt.r4;
im_r4_p = R_belt.im_r4_p;
%% Set up parameters
limit_area = 3000;%the minimum area of region that can be seen as an object
threshold = 90;%threshold for object recognition
dis_enter = 150;%enter distance (coordinate x)
dis_enter_y = 80;%enter dista nce (coordinate y)
dis_exit = 185;%exit distance (coordinate x)
%% Preprocessing
im_r4 = im_c(r4(3):r4(4),r4(1):r4(2),:);
im_channel = rgb2gray(im_r4);
im_r4 = abs(im_r4_p-im_r4)+abs(im_r4-im_r4_p);
ch = 3;
%imr4eqc = 0.33*(im_r4(:,:,1)+im_r4(:,:,2)+im_r4(:,:,3));
imr4eqc = rgb2gray(im_r4);

imr4eq = histeq(imr4eqc);
imr4t = imr4eq;
%speed up here
pt2 = [];
stp2 = 20;
stp1 = 20;
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

loc = find(pt2>threshold);

if isempty(loc)
    im_color = im_c;
    return;
end

loc_something = [ loc(1) loc(end)];
% find template
%%% TODO : loc_something might be empty

%T = rgb2gray(imread('template1.jpg'));
I = im_channel;
% htm=vision.TemplateMatcher('ROIInputPort',true, 'ROIValidityOutputPort',true,...
%     'BestMatchNeighborhoodOutputPort',true,'NeighborhoodSize',3,'OutputValue','Best match location') ;

[cpro_r4,template] = my_template_match_main(loc_something, imr4eqc, template , 0.7);
% [cpro_r4,template] = my_template_match_main(loc_something, I, template , 0.7);

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
temp_r4 = [];
for i = 1:size(cpro_r4,1)
    if (cpro_r4(i).Area>limit_area)
        temp_r4 = [temp_r4; ...
             double([cpro_r4(i).Centroid(1) cpro_r4(i).Centroid(2) cpro_r4(i).Area 0 i]) ];
    end
end


pcnt_r4 = size(temp_r4,1);
%%
if (pcnt_r4~=0)
    
    if (r4_cnt ~= 0)
        
        r4_obj(:,5) = 0;   %clear the status of FOUND
        dis_r4 = [];
        dis_bin = 100*ones(r4_cnt,r4_cnt);
        for i = 1:r4_cnt
            for j = 1:pcnt_r4
                dis_r4(i,j) = sqrt((r4_obj(i,1)-temp_r4(j,1))^2+(r4_obj(i,2)-temp_r4(j,2))^2);
            end
        end
        
        sort_prev = [];
        sort_now = [];
        
        %sort the minimum distance
        for i = 1:r4_cnt
            sort_prev(i) = find(dis_r4(i,:)==min(dis_r4(i,:)),1);
        end
        for i = 1:pcnt_r4
            sort_now(i) = find(dis_r4(:,i)==min(dis_r4(:,i)),1);
        end
        
        %%%%%%%%%
        % double match?
        for i = 1:r4_cnt
            if (sort_now(sort_prev(i))==i && abs(temp_r4(sort_prev(i),2)-r4_obj(i,2))<50)
                r4_obj(i,1:2) = 0.5*temp_r4(sort_prev(i),1:2)+0.5*r4_obj(i,1:2);
                r4_obj(i,3) = temp_r4(sort_prev(i),3);
                r4_obj(i,5) = 1;
                temp_r4(sort_prev(i),4) = 1;
            end
        end
        
        
        % check the distance between two bins
        for i = 1:r4_cnt
            if (i+1) <= r4_cnt
                dis_bin(i+1:r4_cnt,i) = sqrt((r4_obj(i+1:r4_cnt,1)-r4_obj(i,1)).^2 ...
                    +(r4_obj(i+1:r4_cnt,2)-r4_obj(i,2)).^2);
            end
        end
        
        %% push the bins ahead if they are neighbors
        for i = 1:r4_cnt
            min_dis_bin=min([min(dis_bin(:,i)) min(dis_bin(i,:))]);
            if min_dis_bin<=40
                [m_a, m_b]=find(dis_bin==min_dis_bin(1,1));
                if(m_a==i)
                    idx=m_b;
                else
                    idx=m_a;
                end
                if (r4_obj(i,2)>100 && r4_obj(i,2)>r4_obj(idx,2))
                    r4_obj(i,2)=r4_obj(i,2)+10;
                end
            end
        end
        
        %detect entering
        for i = 1:pcnt_r4
            
            if (temp_r4(i,4)==0)
                if (temp_r4(i,2)<dis_enter && temp_r4(i,1)<dis_enter_y)
                    
                    dis1 = pdist2(r4_obj(:,1:2),temp_r4(i,1:2),'euclidean');
                    if min(dis1)>=50
                        %py1=max(1,round(temp_r4(i,2)-35));
                        %py2=min(R_belt.r4(4)-R_belt.r4(3),round(temp_r4(i,2)+35));
                        % double check if there is a people nearby
                        max_dist_b_p=72;
                        r1_edge=r1_obj(:,1:2)+[R_dropping.r1(1) R_dropping.r1(3)];
                        r1_edge(:,1)=r1_edge(:,1)-sqrt(r1_obj(:,3));
                        r1_edge(r1_edge(:,1)<R_dropping.r1(1),1)=R_dropping.r1(1);
                        dist_b_p=pdist2(r1_edge,temp_r4(i,1:2)+[R_belt.r4(1) R_belt.r4(3)],'euclidean');
                        dist_b_p_min=min(dist_b_p);
                        if dist_b_p_min>max_dist_b_p
                            continue;
                        end
                        r4_cnt=r4_cnt+1;
                        %% find out whose bin is put on the belt
                        r4_lb=r4_lb+1;
                        bin_belong=find(dist_b_p==dist_b_p_min);
                        r4_obj=[r4_obj;temp_r4(i,1:3) r4_lb 1 r1_obj(bin_belong(1,1),4)];
                        %save the detected bin
                        %save_bin_path='../detected_bin/';
                        %px = temp_r4(i,1)+R_belt.r4(1);
                        %py = temp_r4(i,2)+R_belt.r4(3);
                        %wintx = 35;
                        %winty = 25;
                        %imwrite(im_c(py-winty:py+winty,px-wintx:px+wintx),...
                        %    [save_bin_path 'b' num2str(r4_lb) ' p' num2str(r1_obj(bin_belong(1,1),4)) '.jpg'])
                    end
                end
            end
        end
        
        %detect exiting
        for i = 1:r4_cnt
            if (r4_obj(i,2)>=dis_exit)
                bin_seq = [bin_seq;r4_obj(i,:)];
                r4_obj(i:end-1,:) = r4_obj(i+1:end,:);
                r4_cnt = r4_cnt-1;
                r4_obj = r4_obj(1:r4_cnt,:);
                disp('delete!');
                break
            elseif (r4_obj(i,2)>=(dis_exit-40) && isempty(find(r1_obj(:,4)==r4_obj(i,6), 1)))
                bin_seq = [bin_seq;r4_obj(i,:)];
                r4_obj(i:end-1,:) = r4_obj(i+1:end,:);
                r4_cnt = r4_cnt-1;
                r4_obj = r4_obj(1:r4_cnt,:);
                disp('delete!');
                break
            end
            
        end
        
    else %r4_cnt == 0
        
        for q = 1:pcnt_r4
            if (temp_r4(q,2)<dis_enter && temp_r4(q,1)<dis_enter_y && temp_r4(q,3)>limit_area)
                %find the maximum area of the temp region
                %py1=max(1,round(temp_r4(q,2)-35));
                %py2=min(size(im_channel,1),round(temp_r4(q,2)+35));
                % double check if there is a people nearby
                max_dist_b_p=72;
                if size(r1_obj,1)==0
                    continue;
                end
                r1_edge=r1_obj(:,1:2)+[R_dropping.r1(1) R_dropping.r1(3)];
                r1_edge(:,1)=r1_edge(:,1)-sqrt(r1_obj(:,3));
                r1_edge(r1_edge(:,1)<R_dropping.r1(1),1)=R_dropping.r1(1);
                dist_b_p=pdist2(r1_edge,temp_r4(q,1:2)+[R_belt.r4(1) R_belt.r4(3)],'euclidean');
                dist_b_p_min=min(dist_b_p);
                if dist_b_p_min>max_dist_b_p
                    continue;
                end
                r4_cnt=r4_cnt+1;
                %% find out whose bin is put on the belt
                bin_belong=find(dist_b_p==dist_b_p_min);
                r4_lb=r4_lb+1;
                r4_obj=[r4_obj;temp_r4(q,1:3) r4_lb 1 r1_obj(bin_belong(1,1),4)];
                %save the detected bin
%                 save_bin_path='./detected_bin/';
%                 px = temp_r4(q,1)+R_belt.r4(1);
%                 py = temp_r4(q,2)+R_belt.r4(3);
%                 wintx = 35;
%                 winty = 25;
%                 imwrite(im_c(py-winty:py+winty,px-wintx:px+wintx),...
%                     [save_bin_path 'b' num2str(r4_lb) ' p' num2str(r1_obj(bin_belong(1,1),4)) '.jpg'])
            end
        end
    end
    
end
im_color = im_c;
R_belt.r4_obj = r4_obj;
R_belt.r4_cnt = r4_cnt;
R_belt.r4_lb = r4_lb;
R_dropping.r1_obj = r1_obj;

end



% if ~isempty(loc_something)
%     
%     a = loc_something(1); b = loc_something(end);
%     
%     x = 1; y = a;
%     wid = size(im_channel,2);
%     hei = b - a + 1;
%     
%     [Loc, NVals,~,~] = step(htm,I,T,[x y wid hei]);
%     %NVals
%     
%    % htm1=vision.TemplateMatcher( 'BestMatchNeighborhoodOutputPort',true,'NeighborhoodSize',3,'OutputValue','Metric matrix') ;
%    % Metric = step(htm1, I, T);
%     
%    % [Loc1, NVals1,~,~] = step(htm,I,T,[1 1 83 65]);
%    % NVals1
%     
%    % thr_nval = NVals( floor(size(NVals,1) / 2), floor(size(NVals,2) / 2 ));
%     
%     height = 64;
%     
%     if rem( size(T,1),2 ) == 0
%         dim_y = Loc(2) - size(T,1) / 2 + 1;
%     else
%         dim_y = ceil(Loc(2) - size(T,1) / 2 );
%     end
%     
%     
%     %bbox = int64 ([ 1 max(1,py-height_T/2) wid  min(py+height_T/2, size(I,1)) ] );
%     
%     im_and_shape = insertShape( I,'Rectangle',[ 1 dim_y wid height ]);
%     
%     figure(1);imshow(im_and_shape);
%     drawnow;
%     
%     %loc_something(1) = loc_something(1) - 
%     
% end

% width = min( size(T,2), size(I,2) );
% I = I(:, 1:width);
% T = T(:, 1:width);


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
% %% Acquire bin quantity
% %try to split the bigger area
% split_area = 4100;
% size_lb = size(lb_r4);
% for i = 1:size(cpro_r4,1)
%     if (cpro_r4(i).Area>split_area*2)
%         pos_x = max(1,int16(cpro_r4(i).BoundingBox(2)));
%         pos_y = max(1,int16(cpro_r4(i).BoundingBox(1)));
%         pos_x_end = min(int16(cpro_r4(i).BoundingBox(2)+cpro_r4(i).BoundingBox(4)),size_lb(1));
%         pos_y_end = min(int16(cpro_r4(i).BoundingBox(1)+cpro_r4(i).BoundingBox(3)),size_lb(2));
%         blob_region = im_channel(pos_x:pos_x_end,pos_y:pos_y_end);
%         f_n = zeros(1,3);
%         for n = 1:3
%             f_n(1,n)=0;
%             std_I=zeros(1,n);
%             mean_I=zeros(1,n);
%             size_b=size(blob_region);
%             part=round(size_b(1,1)/n);
%             for j=1:n
%                 end_part=j*part;
%                 if(size_b(1,1)<end_part)
%                     end_part=size_b(1,1);
%                 end
%                 I_j=im2double(blob_region((1+(j-1)*part):end_part,:));
%                 std_I(1,j)=std(I_j(:),1);
%                 mean_I(1,j)=mean(I_j(:));
%             end
%             if n==1  %%%?????
%                 f_n(1,1)=0;
%             else
%                 f_n(1,n)=mean(std_I)/std(mean_I,1);
%             end
%         end
%         max_pos = find(f_n==max(f_n));
%         
%         if(cpro_r4(i).Area>split_area*3)
%             %upper region
%             temp_struct1=struct('Area',cpro_r4(i).Area/3,...
%                 'Centroid',[cpro_r4(i).Centroid(1), cpro_r4(i).Centroid(2)-cpro_r4(i).BoundingBox(4)/3],...
%                 'BoundingBox', [cpro_r4(i).BoundingBox(1:3) cpro_r4(i).BoundingBox(4)/3]);
%             
%             %middle region
%             temp_struct2=struct('Area',cpro_r4(i).Area/3,...
%                 'Centroid',cpro_r4(i).Centroid(1:2),...
%                 'BoundingBox', [cpro_r4(i).BoundingBox(1) cpro_r4(i).BoundingBox(2)+cpro_r4(i).BoundingBox(4)/3 ...
%                 cpro_r4(i).BoundingBox(3) cpro_r4(i).BoundingBox(4)/3]);
%             
%             %down region
%             temp_struct3=struct('Area',cpro_r4(i).Area/3,...
%                 'Centroid',[cpro_r4(i).Centroid(1), cpro_r4(i).Centroid(2)+cpro_r4(i).BoundingBox(4)/3],...
%                 'BoundingBox', [cpro_r4(i).BoundingBox(1) cpro_r4(i).BoundingBox(2)+cpro_r4(i).BoundingBox(4)/3*2 ...
%                 cpro_r4(i).BoundingBox(3) cpro_r4(i).BoundingBox(4)/3]);
%             
%             cpro_r4 = [cpro_r4;temp_struct1;temp_struct2;temp_struct3];
%             cpro_r4(i).Area = -1;
%         elseif(max_pos>=2)
%             %upper region
%             temp_struct1=struct('Area',cpro_r4(i).Area/2,...
%                 'Centroid',[cpro_r4(i).Centroid(1), cpro_r4(i).Centroid(2)-cpro_r4(i).BoundingBox(4)/4],...
%                 'BoundingBox', [cpro_r4(i).BoundingBox(1:3) cpro_r4(i).BoundingBox(4)/2]);
%             %bottom region
%             temp_struct2=struct('Area',cpro_r4(i).Area/2,...
%                 'Centroid',[cpro_r4(i).Centroid(1), cpro_r4(i).Centroid(2)+cpro_r4(i).BoundingBox(4)/4],...
%                 'BoundingBox', [cpro_r4(i).BoundingBox(1) cpro_r4(i).Centroid(2) cpro_r4(i).BoundingBox(3) cpro_r4(i).BoundingBox(4)/2]);
%             
%             cpro_r4 = [cpro_r4;temp_struct1;temp_struct2];
%             cpro_r4(i).Area=-1;
%             %lb_r1(int16(cpro_r1(i).Centroid(2)),:)=0;
%         end
%     end
% end


