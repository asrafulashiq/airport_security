clear all;
%%
filename='out.avi';
v = VideoReader(filename);

end_f=v.NumberOfFrames;
%start_f=10000;
start_f=11000;
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
r1=[round(region_pos1(1)) round(region_pos1(3)+region_pos1(1)) ...
    round(region_pos1(2)) round(region_pos1(4)+region_pos1(2))];
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
%% tracking the people
%get the region 1 of the image
im_r1=im_c(r1(3):r1(4),r1(1):r1(2),:);
imfn=im_r1;
im_r1=abs(im_r1_p-im_r1)+abs(im_r1-im_r1_p);

im2_b=im2bw(im_r1,0.18);

%filter the image with guassian filter
h = fspecial('gaussian',[5,5], 2); 
im2_b=imfilter(im2_b,h);
im2_b2=im2_b;

%close operation for the image
se = strel('disk',10);
im2_b=imclose(im2_b,se);

[row col d]=size(im_c);

%result for region 1
[row col]=size(im2_b);

%the orignal code
%add some color to the foreground it detected
for i=1:row
    for j=1:col
        if (im2_b(i,j)==1)
            imfn(i,j,1)=219;
        end           
    end
end

lb_r1=bwlabel(im2_b);
cpro_r1=regionprops(lb_r1,'Centroid','Area','Orientation','BoundingBox');
% the number of person in region 1
pcnt_r1=size(cpro_r1,1);


temp_r1=[];

%filtered with area
%orignal setting
%limit_area=300;
%the minimum area of region that can be seen as an object
limit_area=1200;
for i=1:pcnt_r1
    if (cpro_r1(i).Area>limit_area)
    temp_r1=[temp_r1; [cpro_r1(i).Centroid(1) cpro_r1(i).Centroid(2) cpro_r1(i).Area 0 i]];
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
    
    
    
    
%%   
    %merge_area=1000
    merge_area=2000;
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
                    else (t_pro.Orientation<-70)
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
    
% detect entering
    for i=1:pcnt_r1
        if (temp_r1(i,4)==0)
           %the condtion  odetermine where is the entrance
           %if ((r1(2)-r1(1)-temp_r1(i,1))<50)
%          if ((r1(3)-temp_r1(i,2))<50 && abs(r1(2)/2+r1(1)/2-temp_r1(i,1))<120)
           %dis_enter=50;
           dis_enter=30;
           dis_enter_y=30;
           if ((temp_r1(i,2)-r1(3))<dis_enter)
                  r1_cnt=r1_cnt+1;
                  r1_obj=[r1_obj;temp_r1(i,1:3) r1_lb+1 1];  
                  temp_r1(i,4)=1;
                  r1_lb=r1_lb+1;
           end           
        end
    end
    
    
%    detect exiting
dis_exit=100;
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

    dis_exit=100;
    %add only one object with the maximum area
    if ((r1(4)-temp_r1(1,2))>=dis_exit)
        r1_cnt=1;
        r1_obj(1,:)=[temp_r1(find(temp_r1(:,3)==max(temp_r1(:,3))),1:3) 1 1]; 
        r1_lb=1;
    end
 end    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DISPLAY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure_handle=figure(1);
%if (rem(n_im,10)==0)
if(1)
imshow(imfn);
hold on;
   
wintx=30;
winty=30;
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
