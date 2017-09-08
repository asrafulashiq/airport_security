clear all;
%%
filename='out.avi';
v = VideoReader(filename);

end_f=v.NumberOfFrames;
%start_f=10000;
start_f=10200;
%%
cut=1;

figure(1);
%maximize;

se = strel('disk',10);  

%im_p=imread('I:\v1027\back.jpg');
im_p=imread([filename(1:end-4) '_back.jpg']);
%files = dir('I:\v1027\*.jpg');

%imname=files(n_im).name 

%% region setting, need to be changed
load region_pos1.mat
load region_pos2.mat
%Region1:  droping bags
r1=[round(region_pos2(1)) round(region_pos2(3)+region_pos2(1)) ...
    round(region_pos2(2)) round(region_pos2(4)+region_pos2(2))];
%r1=[390-120 390+120 357-150 357+690];
%Region2:  Pick up bags
r2=[340-70 340+70 784-200 784+200];
%Region3:   Staffs
r3=[153-50 153+50 664-350 664+350];
%Region4:  Belt
r4=[240-30 245+30 605-350 605+350];

%%
% im_p2=imread('ims1.jpg');
% im_p(r4(3):r4(4),r4(1):r4(2),:)=im_p2(r4(3):r4(4),r4(1):r4(2),:);
im_r1_p=im_p(r1(3):r1(4),r1(1):r1(2),:);

%object information for each region
r1_obj=[];

%object count for each region
r1_cnt=0;

%Object Labels
r1_lb=0;

%%
%speed=round(round(v.FrameRate)/10);
speed=1;
for n_im=start_f:speed:end_f

%resize to speed up

im_c = imresize(read(v,n_im),0.25);
im_c = imrotate(im_c, -90);
n_im
% [M,F] = mode(im_c(:));
% if (M<10 &&  F>=0.4*480*272*3)
%     continue
% end

%get the region 1 of the image
im_r1=im_c(r1(3):r1(4),r1(1):r1(2),:);
im_channel=rgb2gray(im_r1);
imfn=im_r1;
im_r1=abs(im_r1_p-im_r1)+abs(im_r1-im_r1_p);

% im2_b=im2bw(im_r1,0.18);
im2_b=im2bw(im_r1,0.18);
im_r12=im_r1;
im_r12(im2_b==0)=0;
im2_b=im2bw(im_r12,0.2);
% im_r1=rgb2gray(im_r1);
% im_r1_p1=rgb2gray(im_r1_p);
% im_r1=abs(im_r1_p1-im_r1)+abs(im_r1-im_r1_p1);

% im2_b1=histeq(im_r1);
% im2_b=im2bw(im2_b1,0.75);
%filter the image with guassian filter
h = fspecial('gaussian',[5,5], 2); 
im2_b=imfilter(im2_b,h);
im2_b2=im2_b;

%close operation for the image
%default r=10
se = strel('disk',15);
im2_b=imclose(im2_b,se);

[row col d]=size(im_c);

%result for region 1
[row col]=size(im2_b);

%rewrite to speed up
imfn_temp=imfn(:,:,1);
imfn_temp(im2_b(:,:)==1)=219;
imfn(:,:,1)=imfn_temp;

%the orignal code
%add some color to the foreground it detected
% for i=1:row
%     for j=1:col
%         if (im2_b(i,j)==1)
%             imfn(i,j,1)=219;
%         end           
%     end
% end

lb_r1=bwlabel(im2_b);
cpro_r1=regionprops(lb_r1,'Centroid','Area','Orientation','BoundingBox');
% the number of person in region 1
pcnt_r1=size(cpro_r1,1);
%%
%try to spilt the bigger area

split_area=4200;
size_lb=size(lb_r1);
for i=1:pcnt_r1
    if (cpro_r1(i).Area>split_area*2)
        pos_x=max(1,int16(cpro_r1(i).BoundingBox(2)));
        pos_y=max(1,int16(cpro_r1(i).BoundingBox(1)));
        pos_x_end=min(int16(cpro_r1(i).BoundingBox(2)+cpro_r1(i).BoundingBox(4)),size_lb(1));
        pos_y_end=min(int16(cpro_r1(i).BoundingBox(1)+cpro_r1(i).BoundingBox(3)),size_lb(2));
        blob_region=im_channel(pos_x:pos_x_end,pos_y:pos_y_end);
        f_n=zeros(1,3);
%         f_n(1,1)=std(blob_region(:))/mean(blob_region(:));
        for n=1:3
            f_n(1,n)=0;
            std_I=zeros(1,n);
            mean_I=zeros(1,n);
            size_b=size(blob_region);
            part=round(size_b(1,1)/n);
            for j=1:n
                end_part=j*part;
                if(size_b(1,1)<end_part)
                    end_part=size_b(1,1);
                end
                I_j=im2double(blob_region((1+(j-1)*part):end_part,:));
                std_I(1,j)=std(I_j(:),1);
                mean_I(1,j)=mean(I_j(:));
            end
            if n==1
            f_n(1,1)=0;
            else
            f_n(1,n)=mean(std_I)/std(mean_I,1);
            end
        end
        max_pos=find(f_n==max(f_n));
        
       if(cpro_r1(i).Area>split_area*3)
            %upper region
            temp_struct1=struct('Area',cpro_r1(i).Area/3,...
                                'Centroid',[cpro_r1(i).Centroid(1), cpro_r1(i).Centroid(2)-cpro_r1(i).BoundingBox(4)/3],...
                                'BoundingBox', [cpro_r1(i).BoundingBox(1:3) cpro_r1(i).BoundingBox(4)/3],...
                                'Orientation', cpro_r1(i).Orientation);
            %middle region
            temp_struct2=struct('Area',cpro_r1(i).Area/3,...
                                'Centroid',cpro_r1(i).Centroid(1:2),...
                                'BoundingBox', [cpro_r1(i).BoundingBox(1) cpro_r1(i).BoundingBox(2)+cpro_r1(i).BoundingBox(4)/3 ...
                                                cpro_r1(i).BoundingBox(3) cpro_r1(i).BoundingBox(4)/3],...
                                'Orientation', cpro_r1(i).Orientation);
            %down region
            temp_struct3=struct('Area',cpro_r1(i).Area/3,...
                                'Centroid',[cpro_r1(i).Centroid(1), cpro_r1(i).Centroid(2)+cpro_r1(i).BoundingBox(4)/3],...
                                'BoundingBox', [cpro_r1(i).BoundingBox(1) cpro_r1(i).BoundingBox(2)+cpro_r1(i).BoundingBox(4)/3*2 ...
                                                cpro_r1(i).BoundingBox(3) cpro_r1(i).BoundingBox(4)/3],...
                                'Orientation', cpro_r1(i).Orientation);
            
            cpro_r1=[cpro_r1;temp_struct1;temp_struct2;temp_struct3];
            cpro_r1(i).Area=-1;
        elseif(max_pos==2 || max_pos==3)
            %upper region
            temp_struct1=struct('Area',cpro_r1(i).Area/2,...
                                'Centroid',[cpro_r1(i).Centroid(1), cpro_r1(i).Centroid(2)-cpro_r1(i).BoundingBox(4)/4],...
                                'BoundingBox', [cpro_r1(i).BoundingBox(1:3) cpro_r1(i).BoundingBox(4)/2],...
                                'Orientation', cpro_r1(i).Orientation);
            %bottom region
            temp_struct2=struct('Area',cpro_r1(i).Area/2,...
                                'Centroid',[cpro_r1(i).Centroid(1), cpro_r1(i).Centroid(2)+cpro_r1(i).BoundingBox(4)/4],...
                                'BoundingBox', [cpro_r1(i).BoundingBox(1) cpro_r1(i).Centroid(2) cpro_r1(i).BoundingBox(3) cpro_r1(i).BoundingBox(4)/2],...
                                'Orientation', cpro_r1(i).Orientation);
            
            cpro_r1=[cpro_r1;temp_struct1;temp_struct2];
            cpro_r1(i).Area=-1;
            %lb_r1(int16(cpro_r1(i).Centroid(2)),:)=0;
        end
    end
end
% cpro_r1=regionprops(lb_r1,'Centroid','Area','Orientation','BoundingBox');
% the number of person in region 1
pcnt_r1=size(cpro_r1,1);
%%

for i=1:row
    for j=1:col
        if (lb_r1(i,j)>0)
            imfn(i,j,1)=219;
        end           
    end
end


temp_r1=[];

%filtered with area
%orignal setting
%limit_area=300;
%the minimum area of region that can be seen as an object
limit_area=4000;
split_area=4000;
for i=1:pcnt_r1
    if (cpro_r1(i).Area>limit_area)
            temp_r1=[temp_r1; ...
                [cpro_r1(i).Centroid(1) cpro_r1(i).Centroid(2) cpro_r1(i).Area 0 i]];
    end
end   

pcnt_r1=size(temp_r1,1);

if (pcnt_r1~=0)

 if (r1_cnt~=0)
     
    r1_obj(:,5)=0;   %clear the status of FOUND 
     
    dis_r1=[];
    for i=1:r1_cnt
        for j=1:pcnt_r1
            dis_r1(i,j)=sqrt((r1_obj(i,1)-temp_r1(j,1))^2+(r1_obj(i,2)-temp_r1(j,2))^2);
           % distance(r1_obj(i,1:2), temp_r1(j,1:2));
        end
    end
    
    sort_t=[];
    sort_o=[];
    
    %sort the minimum distance
    for i=1:r1_cnt
        sort_t(i)=find(dis_r1(i,:)==min(dis_r1(i,:)),1);
    end
 
    for i=1:pcnt_r1
        sort_o(i)=find(dis_r1(:,i)==min(dis_r1(:,i)),1);
    end
    %% change distance here?
    p_dis_limit=80;
    %p_dis_limit=120;
    for i=1:r1_cnt
        % double match
        if (sort_o(sort_t(i))==i)
            r1_obj(i,1:2)=0.5*temp_r1(sort_t(i),1:2)+0.5*r1_obj(i,1:2);
            r1_obj(i,3)=temp_r1(sort_t(i),3);
            r1_obj(i,5)=1;
            temp_r1(sort_t(i),4)=1;
            
        else
            ob_mat=find(sort_o==i);
            % object match
            if (~isempty(ob_mat))
                ob_mat_sz=size(ob_mat,2);
                if (ob_mat_sz==1)
                    if (dis_r1(i,ob_mat(1))<120) %distance constraint
                    r1_obj(i,1:2)=0.5*temp_r1(ob_mat(1),1:2)+0.5*r1_obj(i,1:2);
                    r1_obj(i,3)=temp_r1(ob_mat(1),3);
                    r1_obj(i,5)=1;
                    temp_r1(ob_mat(1),4)=1;
                    end
                else
                    mrg_ind=find(dis_r1(ob_mat,i)==min(dis_r1(ob_mat,i)));
                    r1_obj(i,1:2)=0.5*temp_r1(mrg_ind,1:2)+0.5*r1_obj(i,1:2);
                    r1_obj(i,3)=temp_r1(mrg_ind,3);
                    r1_obj(i,5)=1;
                    temp_r1(mrg_ind,4)=1;
                end
                % more than one person to one object

            elseif (dis_r1(i,sort_t(i))<p_dis_limit)
                p_merg=find(sort_t==sort_t(i));
                
                   t_pro=cpro_r1(temp_r1(sort_t(i),5));
                     m_cnt=size(p_merg,2);
                     
                     if (m_cnt==2)
                     
                        km=i;
                        
                        to_merg_ind=find(p_merg~=i,1);
                        
                        merg_ind=p_merg(to_merg_ind);
                        
                        if (t_pro.Centroid(2)>0.4*row)&&(t_pro.Centroid(2)<0.6*row)
                            if(t_pro.Orientation>20)&&(t_pro.Orientation<70)
                                merge_p(1,:)=[t_pro.Centroid(1)+t_pro.BoundingBox(3)/3 t_pro.Centroid(2)-t_pro.BoundingBox(4)/3];
                                merge_p(2,:)=[t_pro.Centroid(1)-t_pro.BoundingBox(3)/3 t_pro.Centroid(2)+t_pro.BoundingBox(4)/3];
                            elseif (t_pro.Orientation>70)||(t_pro.Orientation<-70)
                                merge_p(1,:)=[t_pro.Centroid(1) t_pro.Centroid(2)-t_pro.BoundingBox(4)/3];
                                merge_p(2,:)=[t_pro.Centroid(1) t_pro.Centroid(2)+t_pro.BoundingBox(4)/3];
                            elseif (t_pro.Orientation<-20)&&(t_pro.Orientation>-70)
                                merge_p(1,:)=[t_pro.Centroid(1)-t_pro.BoundingBox(3)/3 t_pro.Centroid(2)-t_pro.BoundingBox(4)/3];
                                merge_p(2,:)=[t_pro.Centroid(1)+t_pro.BoundingBox(3)/3 t_pro.Centroid(2)+t_pro.BoundingBox(4)/3];
                            else
                                merge_p(1,:)=[t_pro.Centroid(1)-t_pro.BoundingBox(3)/3 t_pro.Centroid(2)];
                                merge_p(2,:)=[t_pro.Centroid(1)+t_pro.BoundingBox(3)/3 t_pro.Centroid(2)];
                            end
                        else
                            if(t_pro.Orientation>0)
                                merge_p(1,:)=[t_pro.Centroid(1)+t_pro.BoundingBox(3)/3 t_pro.Centroid(2)-t_pro.BoundingBox(4)/3];
                                merge_p(2,:)=[t_pro.Centroid(1)-t_pro.BoundingBox(3)/3 t_pro.Centroid(2)+t_pro.BoundingBox(4)/3];
                            else 
                                merge_p(1,:)=[t_pro.Centroid(1)-t_pro.BoundingBox(3)/3 t_pro.Centroid(2)-t_pro.BoundingBox(4)/3];
                                merge_p(2,:)=[t_pro.Centroid(1)+t_pro.BoundingBox(3)/3 t_pro.Centroid(2)+t_pro.BoundingBox(4)/3];
                            end
                        end
                    
                      
                        r1_obj(km,3)=temp_r1(sort_t(km),3);
                        r1_obj(km,5)=1;
                        temp_r1(sort_t(km),4)=1;
                        
                        dis_mer(1)=sqrt((r1_obj(km,1)-merge_p(1,1))^2+(r1_obj(km,2)-merge_p(1,2))^2);
                        dis_mer(2)=sqrt((r1_obj(km,1)-merge_p(2,1))^2+(r1_obj(km,2)-merge_p(2,2))^2);
                        
                        if dis_mer(1)<dis_mer(2)
                            r1_obj(km,1:2)=merge_p(1,:);
                            r1_obj(merg_ind,1:2)=merge_p(2,:);
                        else
                            r1_obj(km,1:2)=merge_p(2,:);
                            r1_obj(merg_ind,1:2)=merge_p(1,:);
                        end
       
                     end
                
            end
        end
    end
    
    
    
    
%
    %merge_area=1000
    merge_area=4000*2;
    %handle the merge and split
    for i=1:r1_cnt
        if (dis_r1(i,sort_t(i))<p_dis_limit)
            if (size(find(sort_t==sort_t(i)),2)==1)
                r1_obj(i,1:2)=0.5*temp_r1(sort_t(i),1:2)+0.5*r1_obj(i,1:2);
            elseif (size(find(sort_t==sort_t(i)),2)==2)
                t_pro=cpro_r1(temp_r1(sort_t(i),5));
                if (t_pro.Area>merge_area)
                    
                    if(t_pro.Orientation>20)&&(t_pro.Orientation<70)
                        merge_p(1,:)=[t_pro.Centroid(1)+t_pro.BoundingBox(3)/3 t_pro.Centroid(2)-t_pro.BoundingBox(4)/3];
                        merge_p(2,:)=[t_pro.Centroid(1)-t_pro.BoundingBox(3)/3 t_pro.Centroid(2)+t_pro.BoundingBox(4)/3];
                    elseif (t_pro.Orientation>70)
                        merge_p(1,:)=[t_pro.Centroid(1) t_pro.Centroid(2)-t_pro.BoundingBox(4)/3];
                        merge_p(2,:)=[t_pro.Centroid(1) t_pro.Centroid(2)+t_pro.BoundingBox(4)/3];
                    elseif (t_pro.Orientation<-20)&&(t_pro.Orientation>-70)
                        merge_p(1,:)=[t_pro.Centroid(1)-t_pro.BoundingBox(3)/3 t_pro.Centroid(2)-t_pro.BoundingBox(4)/3];
                        merge_p(2,:)=[t_pro.Centroid(1)+t_pro.BoundingBox(3)/3 t_pro.Centroid(2)+t_pro.BoundingBox(4)/3];
                    elseif (t_pro.Orientation<-70)
                        merge_p(1,:)=[t_pro.Centroid(1)-t_pro.BoundingBox(3)/3 t_pro.Centroid(2)];
                        merge_p(2,:)=[t_pro.Centroid(1)+t_pro.BoundingBox(3)/3 t_pro.Centroid(2)];                        
                    end
                    
                    dis_mer(1)=sqrt((r1_obj(i,1)-merge_p(1,1))^2+(r1_obj(i,2)-merge_p(1,2))^2);
                    dis_mer(2)=sqrt((r1_obj(i,1)-merge_p(2,1))^2+(r1_obj(i,2)-merge_p(2,2))^2);
                    
                    if dis_mer(1)<dis_mer(2)
                        r1_obj(i,1:2)=merge_p(1,:);
                    else
                        r1_obj(i,1:2)=merge_p(2,:);
                    end
                    
                end
                
            elseif (size(find(sort_t==sort_t(i)),2)>2)
                t_pro=cpro_r1(temp_r1(sort_t(i),5));
                if (t_pro.Area>merge_area)
                    
                    merge_p(1,:)=[t_pro.Centroid(1)+t_pro.BoundingBox(3)/3 t_pro.Centroid(2)-t_pro.BoundingBox(4)/3];
                    merge_p(2,:)=[t_pro.Centroid(1)-t_pro.BoundingBox(3)/3 t_pro.Centroid(2)+t_pro.BoundingBox(4)/3];
                    merge_p(3,:)=[t_pro.Centroid(1)+t_pro.BoundingBox(3)/3 t_pro.Centroid(2)+t_pro.BoundingBox(4)/3];
                    merge_p(4,:)=[t_pro.Centroid(1)-t_pro.BoundingBox(3)/3 t_pro.Centroid(2)-t_pro.BoundingBox(4)/3];
                    merge_p(5,:)=[t_pro.Centroid(1)+t_pro.BoundingBox(3)/3 t_pro.Centroid(2)];
                    merge_p(6,:)=[t_pro.Centroid(1)-t_pro.BoundingBox(3)/3 t_pro.Centroid(2)];                   
                    merge_p(7,:)=[t_pro.Centroid(1) t_pro.Centroid(2)+t_pro.BoundingBox(4)/3];
                    merge_p(8,:)=[t_pro.Centroid(1) t_pro.Centroid(2)-t_pro.BoundingBox(4)/3];                         
                    
                    dis_mer(1)=sqrt((r1_obj(i,1)-merge_p(1,1))^2+(r1_obj(i,2)-merge_p(1,2))^2);
                    dis_mer(2)=sqrt((r1_obj(i,1)-merge_p(2,1))^2+(r1_obj(i,2)-merge_p(2,2))^2);
                    dis_mer(3)=sqrt((r1_obj(i,1)-merge_p(3,1))^2+(r1_obj(i,2)-merge_p(3,2))^2);
                    dis_mer(4)=sqrt((r1_obj(i,1)-merge_p(4,1))^2+(r1_obj(i,2)-merge_p(4,2))^2);
                    dis_mer(5)=sqrt((r1_obj(i,1)-merge_p(5,1))^2+(r1_obj(i,2)-merge_p(5,2))^2);
                    dis_mer(6)=sqrt((r1_obj(i,1)-merge_p(6,1))^2+(r1_obj(i,2)-merge_p(6,2))^2);
                    dis_mer(7)=sqrt((r1_obj(i,1)-merge_p(7,1))^2+(r1_obj(i,2)-merge_p(7,2))^2);
                    dis_mer(8)=sqrt((r1_obj(i,1)-merge_p(8,1))^2+(r1_obj(i,2)-merge_p(8,2))^2);
                    
                    mrg_ind=find(dis_mer==min(dis_mer));
                    r1_obj(i,1:2)=merge_p(mrg_ind,:);
                    
                end
            else
                disp('Bang!');
                
                
                
            end
            r1_obj(i,3)=temp_r1(sort_t(i),3);
            r1_obj(i,5)=1;
            temp_r1(sort_t(i),4)=1;
            
            
        end
    end
    
%%       
    % detect entering
    for i=1:pcnt_r1
        if (temp_r1(i,4)==0)
           %the condtion  odetermine where is the entrance
           %if ((r1(2)-r1(1)-temp_r1(i,1))<50)
%          if ((r1(3)-temp_r1(i,2))<50 && abs(r1(2)/2+r1(1)/2-temp_r1(i,1))<120)
           %dis_enter=50;
           %dis_enter=80;
           dis_enter=125;
           dis_enter_y=80;
           if (temp_r1(i,2)<dis_enter && temp_r1(i,1)<dis_enter_y)
              dis=min(pdist2(r1_obj(:,1:2),temp_r1(i,1:2),'euclidean'));
              if dis>=50
                  r1_cnt=r1_cnt+1;
                  r1_obj=[r1_obj;temp_r1(i,1:3) r1_lb+1 1];  
                  temp_r1(i,4)=1;
                  r1_lb=r1_lb+1;
              end
           end           
        end
    end
    
    
%    detect exiting
dis_exit=140;
    for i=1:r1_cnt
      % if (r1_obj(i,5)==0)
            if (r1_obj(i,2)+dis_exit>=r1(4))
                   r1_obj(i:end-1,:)=r1_obj(i+1:end,:);
                   r1_cnt=r1_cnt-1;
                   r1_obj=r1_obj(1:r1_cnt,:);
                   disp('delete!');
                   break
            end
       % end
    
    end
   
    
 else    
    for q=1:pcnt_r1
    %add only one object with the maximum area
    limit_area=1500;
    %dis_enter=80;
    dis_enter=125;
    dis_enter_y=80;
    if (temp_r1(q,2)<dis_enter && temp_r1(q,1)<dis_enter_y && temp_r1(q,3)>limit_area)
        r1_cnt=1;
        r1_obj(1,:)=[temp_r1(q,1:3) 1 1]; 
        r1_lb=1;
        break;
    end
    end
 end
 
 
    
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DISPLAY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure_handle=figure(1);
%if (rem(n_im,10)==0)
if(1)
imshow(imfn);
hold on;

% %%%%%%%%%%%%%%% region 1
% wintx=110;
% winty=140;
% plot(120+[wintx+.5 -(wintx+.5) -(wintx+.5) wintx+.5 wintx+.5],145+[winty+.5 winty+.5 -(winty+.5) -(winty+.5)  winty+.5],'-','color',[ 1.000 0.314 0.510 ],'linewidth',2);
% 
%    
% %%%%%%%%%%%%%%% region 2
% wintx=70;
% winty=200;
% plot(90 + [wintx+.5 -(wintx+.5) -(wintx+.5) wintx+.5 wintx+.5],600 + [winty+.5 winty+.5 -(winty+.5) -(winty+.5)  winty+.5],'-','color',[ 0.170 1.000 0.260 ],'linewidth',2);
%%revise to see the different of template

   
wintx=35;
winty=25;
% r1_obj=sortrows(r1_obj,2);
% for i=1:r1_cnt
%     r1_obj(i,4)=r1_cnt-i+1;
% end
%generate template image
for i=1:r1_cnt
    r1_obj(i,4)=r1_cnt-i+1;
end
if r1_cnt>=1
for i=1:r1_cnt
    
    px=r1_obj(i,1);
    py=r1_obj(i,2);  
    plot(px,py,'+','color',[ 1 1 1 ],'linewidth',2);
    text(px+6,py+6,['p' num2str(r1_obj(i,4))],'color',[ 1 1 1 ]);
    
    plot(px + [wintx+.5 -(wintx+.5) -(wintx+.5) wintx+.5 wintx+.5],py + [winty+.5 winty+.5 -(winty+.5) -(winty+.5)  winty+.5],'-','color',[ 1 1 1 ],'linewidth',2);

end
end
% for i=1:pcnt_r1
%     
%     px=temp_r1(i,1);
%     py=temp_r1(i,2);  
%     plot(px,py,'o','color',[ 1 1 0 ],'linewidth',2);
%     text(px+6,py+6,['t' num2str(i)],'color',[ 1 1 0 ]);
% end


drawnow;

hold off;

%print(figure_handle,'-djpeg','-noui',['D:\\Workplace\\Experiment_Results\\20110111\im' num2str(n_im) '.jpg']);
%print(figure_handle,'-djpeg','-noui',[num2str(n_im) '.jpg']);

 %dis_r1
  %input('press enter');
% % 
%  temp_r1
%  r1_obj
 
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



end
