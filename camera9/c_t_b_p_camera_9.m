clear all;
%%
filename='camera9.mp4';
v = VideoReader(filename);
%the file for the outputvideo
outputVideo = VideoWriter('out_put_res_c9_red.mp4');
outputVideo.FrameRate = v.FrameRate;
open(outputVideo)
%the parameter for the start frame and end frame
end_f=v.NumberOfFrames;
%start_f=10000 3650;
start_f=7000;
%start_f=4350;
%% load net
% load net1
load net500;
size2=[71 88];
size2=[35 44];
shape_vector=size2(1,1)*size2(1,2);
path='./new_bin2/';
%%
%load the empty bin template
template=rgb2gray(imread('template1.jpg'));
template_bin2=template;
[tx,ty]=size(template);
template_bin2(int16(tx/2)-20:int16(tx/2)+20,int16(ty/2)-30:int16(ty/2)+30,:)=0;
bin_no=0;
%%
cut=1;

figure(1);
%maximize;

se = strel('disk',10);  

%im_p=imread('I:\v1027\back.jpg');
im_p=imread('camera9_back.jpg');
%files = dir('I:\v1027\*.jpg');

%imname=files(n_im).name 
%% code to adjust the threshold
max_pt2=[];
pt2_sequence=[];
pt1_sequence=[];
mean_pt2=[];
max_half=[];

%% region setting, need to be changed
load region_pos_c9_1
load region_pos_c9_2
%Region1:  droping bags
r1=[round(region_pos_c9_1(1)) round(region_pos_c9_1(3)+region_pos_c9_1(1)) ...
    round(region_pos_c9_1(2)) round(region_pos_c9_1(4)+region_pos_c9_1(2))];
%Region4:  Belt
%r4=[240-30 245+30 605-350 605+350];
r4=[round(region_pos_c9_2(1)) round(region_pos_c9_2(3)+region_pos_c9_2(1)) ...
    round(region_pos_c9_2(2)) round(region_pos_c9_2(4)+region_pos_c9_2(2))];
cut=5;
% r4(1,1)=r4(1,1)-cut;
r4(1,2)=r4(1,2)+1;
% r1(1,1)=r1(1,1)-2;
% r4(1,3)=r4(1,3)-15;
% r4(1,3)=r4(1,3)-25;
r4(1,4)=r4(1,4)+4*cut;
%r1=[390-120 390+120 357-150 357+690];
%Region2:  Pick up bags
r2=[340-70 340+70 784-200 784+200];
%Region3:   Staffs
r3=[153-50 153+50 664-350 664+350];


%%
% im_p2=imread('ims1.jpg');
% im_p(r4(3):r4(4),r4(1):r4(2),:)=im_p2(r4(3):r4(4),r4(1):r4(2),:);
im_r4_p=im_p(r4(3):r4(4),r4(1):r4(2),:);
im_r1_p=im_p(r1(3):r1(4),r1(1):r1(2),:);

%object information for each region
r1_obj=[];
r4_obj=[];
%object count for each region
r1_cnt=0;
r4_cnt=0;
%Object Labels
r1_lb=0;
r4_lb=0;
%%
%speed=round(round(v.FrameRate)/10);
speed=1;
for n_im=start_f:speed:end_f
im_c = imresize(read(v,n_im),0.25);
im_c = imrotate(im_c, -70+180);
n_im
% if n_im>=11090
% n_im
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
           dis_enter=60;
           dis_enter_y=60;
           if ((temp_r1(i,2)-r1(3))<dis_enter)
                  r1_cnt=r1_cnt+1;
                  r1_obj=[r1_obj;temp_r1(i,1:3) r1_lb+1 1];  
                  temp_r1(i,4)=1;
                  r1_lb=r1_lb+1;
           end           
        end
    end
    
    
%    detect exiting
dis_exit=210;
dis_exit_y=54;
    for i=1:r1_cnt
      % if (r1_obj(i,5)==0)
            if (r1_obj(i,2)>=dis_exit && r1_obj(i,1)>=dis_exit_y)
                   r1_obj(i:end-1,:)=r1_obj(i+1:end,:);
                   r1_cnt=r1_cnt-1;
                   r1_obj=r1_obj(1:r1_cnt,:);
                   disp('delete!');
                   break
            end
       % end
    
    end
   
    
 else    

    dis_enter=60;
    %add only one object with the maximum area
    if ((temp_r1(1,2)-r1(3))<dis_enter)
        r1_cnt=1;
        r1_obj(1,:)=[temp_r1(find(temp_r1(:,3)==max(temp_r1(:,3))),1:3) 1 1]; 
        r1_lb=1;
    end
 end    
end

%% tracking the bin

% [M,F] = mode(im_c(:));
% if (M<10 &&  F>=0.4*480*272*3)
%     continue
% end

%get the region 1 of the image
im_r4=im_c(r4(3):r4(4),r4(1):r4(2),:);
im_channel=rgb2gray(im_r4);
imfn=im_r4;
im_r4=abs(im_r4_p-im_r4)+abs(im_r4-im_r4_p);
ch=1;
imr4eqc=0.33*(im_r4(:,:,ch)+im_r4(:,:,ch)+im_r4(:,:,ch));
imr4eq=histeq(imr4eqc);
imr4t=imr4eq;

pt1=[];
pt2=[];
stp2=20;
stp1=20;
end_step=size(imr4t,1);
for i=1+stp1:(end_step-stp2)
    pt1(i)=var(var(double(imr4t(i-stp2:i+stp2,:))));
    pt2(i)=mean(mean(imr4t(i-stp2:i+stp2,:)));
end
%pt1=medfilt1(pt1,stp2);

thpt1=max(pt1)/4.5;
meanpt2=mean(pt2);
mean_pt2=[mean_pt2 meanpt2];
max_half=[max_half thpt1];
%% orignal code
% imr1t(1:stp,:)=0;
% imr1t(end_step-stp:end,:)=0;
% threshold=130;
% for i=1+stp:(end_step-stp)
%     if ((pt2(i)>threshold))
%         imr1t(i,:)=1;
%     else
%         imr1t(i,:)=0;
%     end
% end
%% speed up here
threshold=140;
val1=max(pt2);
% thpt1=170000;
%test1 15 140
%test2 20 135
thpt1=0;    
max_pt2=[max_pt2 max(pt2)];
pt2_293x1=reshape(pt2,[size(pt2,2) 1]);
pt2_sequence=[pt2_sequence pt2_293x1];
pt1_293x1=reshape(pt1,[size(pt2,2) 1]);
pt1_sequence=[pt1_sequence pt1_293x1];
% if max(pt2)<=180
%     imr4t(:,:)=0;
% else
% imr4t(pt2_293x1>threshold & pt1_293x1>thpt1,:)=1;
% imr4t(pt2_293x1<=threshold | pt1_293x1<=thpt1,:)=0;
imr4t(pt2_293x1>threshold,:)=1;
imr4t(pt2_293x1<=threshold,:)=0;
imr4t(1:stp1,:)=0;
imr4t(end_step-stp2:end,:)=0;
% end
lb_r4=bwlabel(imr4t);
cpro_r4=regionprops(lb_r4,'Centroid','Area','BoundingBox');
% the number of person in region 1
pcnt_r4=size(cpro_r4,1);
%%
%try to spilt the bigger area
split_area=4100;
size_lb=size(lb_r4);
for i=1:pcnt_r4
    if (cpro_r4(i).Area>split_area*2)
        pos_x=max(1,int16(cpro_r4(i).BoundingBox(2)));
        pos_y=max(1,int16(cpro_r4(i).BoundingBox(1)));
        pos_x_end=min(int16(cpro_r4(i).BoundingBox(2)+cpro_r4(i).BoundingBox(4)),size_lb(1));
        pos_y_end=min(int16(cpro_r4(i).BoundingBox(1)+cpro_r4(i).BoundingBox(3)),size_lb(2));
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
        
       if(cpro_r4(i).Area>split_area*3)
            %upper region
            temp_struct1=struct('Area',cpro_r4(i).Area/3,...
                                'Centroid',[cpro_r4(i).Centroid(1), cpro_r4(i).Centroid(2)-cpro_r4(i).BoundingBox(4)/3],...
                                'BoundingBox', [cpro_r4(i).BoundingBox(1:3) cpro_r4(i).BoundingBox(4)/3]);
                               
            %middle region
            temp_struct2=struct('Area',cpro_r4(i).Area/3,...
                                'Centroid',cpro_r4(i).Centroid(1:2),...
                                'BoundingBox', [cpro_r4(i).BoundingBox(1) cpro_r4(i).BoundingBox(2)+cpro_r4(i).BoundingBox(4)/3 ...
                                                cpro_r4(i).BoundingBox(3) cpro_r4(i).BoundingBox(4)/3]);
                             
            %down region
            temp_struct3=struct('Area',cpro_r4(i).Area/3,...
                                'Centroid',[cpro_r4(i).Centroid(1), cpro_r4(i).Centroid(2)+cpro_r4(i).BoundingBox(4)/3],...
                                'BoundingBox', [cpro_r4(i).BoundingBox(1) cpro_r4(i).BoundingBox(2)+cpro_r4(i).BoundingBox(4)/3*2 ...
                                                cpro_r4(i).BoundingBox(3) cpro_r4(i).BoundingBox(4)/3]);
            
            cpro_r4=[cpro_r4;temp_struct1;temp_struct2;temp_struct3];
            cpro_r4(i).Area=-1;
        elseif(max_pos>=2)
            %upper region
            temp_struct1=struct('Area',cpro_r4(i).Area/2,...
                                'Centroid',[cpro_r4(i).Centroid(1), cpro_r4(i).Centroid(2)-cpro_r4(i).BoundingBox(4)/4],...
                                'BoundingBox', [cpro_r4(i).BoundingBox(1:3) cpro_r4(i).BoundingBox(4)/2]);
            %bottom region
            temp_struct2=struct('Area',cpro_r4(i).Area/2,...
                                'Centroid',[cpro_r4(i).Centroid(1), cpro_r4(i).Centroid(2)+cpro_r4(i).BoundingBox(4)/4],...
                                'BoundingBox', [cpro_r4(i).BoundingBox(1) cpro_r4(i).Centroid(2) cpro_r4(i).BoundingBox(3) cpro_r4(i).BoundingBox(4)/2]);
            
            cpro_r4=[cpro_r4;temp_struct1;temp_struct2];
            cpro_r4(i).Area=-1;
            %lb_r1(int16(cpro_r1(i).Centroid(2)),:)=0;
        end
    end
end
% cpro_r1=regionprops(lb_r1,'Centroid','Area','Orientation','BoundingBox');
% the number of person in region 1
pcnt_r4=size(cpro_r4,1);
%
%% add some color to the foreground it detected
[row_max, col_max]=size(im_c);
for i=1:row
    for j=1:col
        if (im2_b(i,j)==1 && i+r1(3)<=row_max && j+r1(1)<=col_max)
            %imfn(i+r4(3),j+r4(1),1)=219;
            im_c(i+r1(3),j+r1(1),1)=219;
        end           
    end
end
[row col]=size(imr4t);

for i=1:row
    for j=1:col
        if (imr4t(i,j)>0 && i+r4(3)<=row_max && j+r4(1)<=col_max)
            im_c(i+r4(3),j+r4(1),3)=219;
        end           
    end
end


temp_r4=[];

%% filtered with area
%orignal setting
%limit_area=300;
%the minimum area of region that can be seen as an object
limit_area=3700;
for i=1:pcnt_r4
    if (cpro_r4(i).Area>limit_area)
            temp_r4=[temp_r4; ...
                [cpro_r4(i).Centroid(1) cpro_r4(i).Centroid(2) cpro_r4(i).Area 0 i]];
    end
end   

pcnt_r4=size(temp_r4,1);
%%
if (pcnt_r4~=0)

 if (r4_cnt~=0)
     
    r4_obj(:,5)=0;   %clear the status of FOUND 
    dis_r4=[];
    dis_bin=100*ones(r4_cnt,r4_cnt);
    for i=1:r4_cnt
        for j=1:pcnt_r4
            dis_r4(i,j)=sqrt((r4_obj(i,1)-temp_r4(j,1))^2+(r4_obj(i,2)-temp_r4(j,2))^2);
           % distance(r1_obj(i,1:2), temp_r1(j,1:2));
        end
    end
    
    sort_t=[];
    sort_o=[];
    
    %sort the minimum distance
    for i=1:r4_cnt
        sort_t(i)=find(dis_r4(i,:)==min(dis_r4(i,:)),1);
    end
 
    for i=1:pcnt_r4
        sort_o(i)=find(dis_r4(:,i)==min(dis_r4(:,i)),1);
    end
    
    for i=1:r4_cnt
        % double match
        if (sort_o(sort_t(i))==i)
            r4_obj(i,1:2)=0.5*temp_r4(sort_t(i),1:2)+0.5*r4_obj(i,1:2);
            r4_obj(i,3)=temp_r4(sort_t(i),3);
            r4_obj(i,5)=1;
            temp_r4(sort_t(i),4)=1;
            
        else
            
            

        end
    end
    for i=1:r4_cnt
        %% check the distance between two bins
        if i+1<=r4_cnt
           dis_bin(i+1:r4_cnt,i)=sqrt((r4_obj(i+1:r4_cnt,1)-r4_obj(i,1)).^2 ...
                                     +(r4_obj(i+1:r4_cnt,2)-r4_obj(i,2)).^2);
        end
    end
    %% push the bins ahead if they are neighbors
    for i=1:r4_cnt
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
%%       
    % detect entering
    for i=1:pcnt_r4
        if (temp_r4(i,4)==0)
           %the condtion  odetermine where is the entrance
           %if ((r1(2)-r1(1)-temp_r1(i,1))<50)
%          if ((r1(3)-temp_r1(i,2))<50 && abs(r1(2)/2+r1(1)/2-temp_r1(i,1))<120)
           %dis_enter=50;
           %dis_enter=80 140;
           dis_enter=200;
           dis_enter_y=80;
           if (temp_r4(i,2)<dis_enter && temp_r4(i,1)<dis_enter_y)
              dis1=pdist2(r4_obj(:,1:2),temp_r4(i,1:2),'euclidean');
              if min(dis1)>=50
                  py1=max(1,round(temp_r4(i,2)-35));
                  py2=min(region_pos_c9_2(4),round(temp_r4(i,2)+35));
%                   temp_bin=im_channel(py1:py2,1:end);
%                   [bx,by]=size(temp_bin);
%                   temp_bin(int16(bx/2)-20:int16(bx/2)+20,int16(by/2)-30:int16(by/2)+30,:)=0;
%                   c = normxcorr2(template_bin2,temp_bin);
%                   max_c=max(c(:));
%                   if max_c<0.5
%                       continue;
%                   end
                  %% bin detection 
%                   by1=max(1,round(temp_r4(i,2)-35));
%                   by2=min(size(im_channel,1),round(temp_r4(i,2)+35));

%                   bin_example=im2double(imresize(im_channel(py1:py2,:),size2))-0.5;
%                   im_vector=reshape(bin_example,[shape_vector,1]);
%                   output=net(im_vector);
%                   if(output(2)<output(1))
%                      continue;
%                   end
                % save detection tesult
%                 by1=max(1,round(temp_r4(i,2)-35))
%                 by2=min(size(im_channel,1),round(temp_r4(i,2)+35));
%                 bin_example=im_channel(by1:by2,:);
%                 imwrite(bin_example,[path 'bin' num2str(bin_no) '.jpg']);
%                 bin_no=bin_no+1;
                %% double check if there is a people nearby
                  max_dis_b_p=72;
                  r1_edge=r1_obj(:,1:2)+[r1(1) r1(3)];
                  r1_edge(:,1)=r1_edge(:,1)-sqrt(r1_obj(:,3));
                  r1_edge(r1_edge(:,1)<r1(1),1)=r1(1);
                  dis_b_p=min(pdist2(r1_edge,temp_r4(i,1:2)++[r4(1) r4(3)],'euclidean'));
                  if dis_b_p>max_dis_b_p
                      continue;
                  end
                  r4_cnt=r4_cnt+1;
                  r4_obj=[r4_obj;temp_r4(i,1:3) r4_lb+1 1];

                %% detect the correlation with empty bin so that that can be detected as new one
                  c = normxcorr2(template,im_channel(py1:py2,1:end));
%                 figure;
%                 imshow(c,[]);
                  [ypeak, xpeak] = find(c==max(c(:)));
                  yoffSet = ypeak-int16(size(template,1)/2);
                  xoffSet = xpeak-int16(size(template,2)/2);
                  dis2=pdist2(r4_obj(:,1:2),[xoffSet(1) yoffSet(1)],'euclidean');
                  no=find(dis2==min(dis2));
                %% use the sum of edge to find the region with the min edge
                  blob=zeros(1,r4_cnt);
                  edge_im=edge(im_channel,'canny',0.25);
                  for b_n=1:r4_cnt
                      x1=max(1,round(r4_obj(b_n,2)-35));
                      x2=min(size(edge_im,1),round(r4_obj(b_n,2)+35));
                      blob(b_n)=sum(sum(edge_im(x1:x2,:)));
                  end
                  no_edge=find(blob==min(blob));
                %% switch if the entering box is less likely to be a empty bin
                  if(no~=size(r4_obj,1) && no_edge~=size(r4_obj,1))
                      no_2=find(dis1==min(dis1));
                      temp_center=r4_obj(no_2(1),1:3);
                      r4_obj(no_2(1),1:3)=temp_r4(i,1:3);
                      r4_obj(end,1:3)=temp_center;
                  end
                  temp_r4(i,4)=1;
                  r4_lb=r4_lb+1;
              end
           end           
        end
    end
    
    
%    detect exiting
    dis_exit=220;
    for i=1:r4_cnt
      % if (r1_obj(i,5)==0)
            if (r4_obj(i,2)>=dis_exit)
                   r4_obj(i:end-1,:)=r4_obj(i+1:end,:);
                   r4_cnt=r4_cnt-1;
                   r4_obj=r4_obj(1:r4_cnt,:);
                   disp('delete!');
                   break
            end
       % end
    
    end
   
    
 else    
    for q=1:pcnt_r4
    %add only one object with the maximum area
    limit_area=3700;
    %dis_enter=80 140;
    dis_enter=200;
    dis_enter_y=80;
    
        if (temp_r4(q,2)<dis_enter && temp_r4(q,1)<dis_enter_y && temp_r4(q,3)>limit_area)
        %find the maximum area of the temp region
%         py1=max(1,round(temp_r4(q,2)-35));
%         py2=min(size(im_channel,1),round(temp_r4(q,2)+35));
%         temp_bin=im_channel(py1:py2,1:end);
%         [bx,by]=size(temp_bin);
%         temp_bin(int16(bx/2)-20:int16(bx/2)+20,int16(by/2)-30:int16(by/2)+30,:)=0;
%         c = normxcorr2(template_bin2,temp_bin);
%         max_c=max(c(:));
%         if max_c<0.5
%             continue;
%         end
            %% bin detection 
%             bin_example=im2double(imresize(im_channel(py1:py2,1:end),size2))-0.5;
%             im_vector=reshape(bin_example,[shape_vector,1]);
%             output=net(im_vector);
%             if(output(2)<output(1))
%                 continue;
%             end
           %% double check if there is a people nearby
            max_dis_b_p=72;
            if size(r1_obj,1)==0
                continue;
            end
            r1_edge=r1_obj(:,1:2)+[r1(1) r1(3)];
            r1_edge(:,1)=r1_edge(:,1)-sqrt(r1_obj(:,3));
            r1_edge(r1_edge(:,1)<r1(1),1)=r1(1);
            dis_b_p=min(pdist2(r1_edge,temp_r4(q,1:2)++[r4(1) r4(3)],'euclidean'));
            if dis_b_p<=max_dis_b_p
                r4_cnt=1;
                r4_obj(1,:)=[temp_r4(q,1:3) 1 1]; 
                % save detection tesult
%                 by1=max(1,round(r4_obj(1,2)-35))
%                 by2=min(size(im_channel,1),round(r4_obj(1,2)+35));
%                 bin_example=im_channel(by1:by2,:);
%                 imwrite(bin_example,[path 'bin' num2str(bin_no) '.jpg']);
%                 bin_no=bin_no+1;
                r4_lb=1;
                break;
            end
        end
    end
 end
     
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DISPLAY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure_handle=figure(1);
%if (rem(n_im,10)==0)
if(1)
%imshow(imfn);
imshow(im_c);
hold on;


   
wintx=35;
winty=25;
% r1_obj=sortrows(r1_obj,2);
% for i=1:r1_cnt
%     r1_obj(i,4)=r1_cnt-i+1;
% end
%generate template image
% for i=1:r1_cnt
%     r1_obj(i,4)=r1_cnt-i+1;
% end
% if r1_cnt==0
%     r4_cnt=0;
%     r4_obj=[];
% end

if r4_cnt>=1
for i=1:r4_cnt
    
    px=r4_obj(i,1)+r4(1);
    py=r4_obj(i,2)+r4(3);
%     if mod(n_im,4)==0
%         by1=max(1,round(r4_obj(i,2)-35))
%         by2=min(size(im_channel,1),round(r4_obj(i,2)+35));
%         bin_example=im_channel(by1:by2,:);
%         imwrite(bin_example,[path 'bin' num2str(bin_no) '.jpg']);
%         bin_no=bin_no+1;
%     end
    plot(px,py,'+','color',[ 1 1 1 ],'linewidth',2);
    text(px+6,py+6,['b' num2str(r4_obj(i,4))],'color',[ 1 1 1 ]);
    
    plot(px + [wintx+.5 -(wintx+.5) -(wintx+.5) wintx+.5 wintx+.5],py + [winty+.5 winty+.5 -(winty+.5) -(winty+.5)  winty+.5],'-','color',[ 1 1 1 ],'linewidth',2);

end
end
wintx=30;
winty=30;

if r1_cnt>=1
for i=1:r1_cnt
    
    px=r1_obj(i,1)+r1(1);
    py=r1_obj(i,2)+r1(3); 
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
%save image to video here
F = getframe;
writeVideo(outputVideo,F.cdata);
%% write image
% imwrite(imr4t,['./jpg_folder/' num2str(n_im) '.jpg']);
% imwrite(F.cdata,['./data/' num2str(n_im) '.jpg']);
if n_im>15800
    break;
end
end
close(outputVideo);


