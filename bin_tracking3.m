clear all;
%%
filename='out.avi';
v = VideoReader(filename);
%the file for the outputvideo
outputVideo = VideoWriter('out_put_res.avi');
outputVideo.FrameRate = v.FrameRate;
open(outputVideo)
%the parameter for the start frame and end frame
end_f=v.NumberOfFrames;
%start_f=10000 3650;
start_f=3500;
%%
%load the empty bin template
template=rgb2gray(imread('template1.jpg'));
template_bin2=template;
[tx,ty]=size(template);
template_bin2(int16(tx/2)-20:int16(tx/2)+20,int16(ty/2)-30:int16(ty/2)+30,:)=0;

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
cut=5;
r1(1,1)=r1(1,1)-cut;
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
if n_im>=11090
n_im
end
% [M,F] = mode(im_c(:));
% if (M<10 &&  F>=0.4*480*272*3)
%     continue
% end

%get the region 1 of the image
im_r1=im_c(r1(3):r1(4),r1(1):r1(2),:);
im_channel=rgb2gray(im_r1);
imfn=im_r1;
im_r1=abs(im_r1_p-im_r1)+abs(im_r1-im_r1_p);

imr1eqc=0.33*(im_r1(:,:,1)+im_r1(:,:,1)+im_r1(:,:,1));

imr1eq=histeq(imr1eqc);

imr1t=imr1eq;

pt1=[];
pt2=[];
stp2=10;
stp1=10;
end_step=size(imr1t,1);
for i=1+stp1:(end_step-stp2)
    pt1(i)=var(var(double(imr1t(i-stp2:i+stp2,:))));
    pt2(i)=mean(mean(imr1t(i-stp2:i+stp2,:)));
end
pt1=medfilt1(pt1,stp2);

thpt1=max(pt1)/2;
meanpt2=mean(pt2);


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
threshold=125;
imr1t(pt2>threshold,:)=1;
imr1t(pt2<=threshold,:)=0;
imr1t(1:stp1,:)=0;
imr1t(end_step-stp2:end,:)=0;

lb_r1=bwlabel(imr1t);
cpro_r1=regionprops(lb_r1,'Centroid','Area','BoundingBox');
% the number of person in region 1
pcnt_r1=size(cpro_r1,1);
%%
%try to spilt the bigger area
split_area=4000;
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
                                'BoundingBox', [cpro_r1(i).BoundingBox(1:3) cpro_r1(i).BoundingBox(4)/3]);
                               
            %middle region
            temp_struct2=struct('Area',cpro_r1(i).Area/3,...
                                'Centroid',cpro_r1(i).Centroid(1:2),...
                                'BoundingBox', [cpro_r1(i).BoundingBox(1) cpro_r1(i).BoundingBox(2)+cpro_r1(i).BoundingBox(4)/3 ...
                                                cpro_r1(i).BoundingBox(3) cpro_r1(i).BoundingBox(4)/3]);
                             
            %down region
            temp_struct3=struct('Area',cpro_r1(i).Area/3,...
                                'Centroid',[cpro_r1(i).Centroid(1), cpro_r1(i).Centroid(2)+cpro_r1(i).BoundingBox(4)/3],...
                                'BoundingBox', [cpro_r1(i).BoundingBox(1) cpro_r1(i).BoundingBox(2)+cpro_r1(i).BoundingBox(4)/3*2 ...
                                                cpro_r1(i).BoundingBox(3) cpro_r1(i).BoundingBox(4)/3]);
            
            cpro_r1=[cpro_r1;temp_struct1;temp_struct2;temp_struct3];
            cpro_r1(i).Area=-1;
        elseif(max_pos>=2)
            %upper region
            temp_struct1=struct('Area',cpro_r1(i).Area/2,...
                                'Centroid',[cpro_r1(i).Centroid(1), cpro_r1(i).Centroid(2)-cpro_r1(i).BoundingBox(4)/4],...
                                'BoundingBox', [cpro_r1(i).BoundingBox(1:3) cpro_r1(i).BoundingBox(4)/2]);
            %bottom region
            temp_struct2=struct('Area',cpro_r1(i).Area/2,...
                                'Centroid',[cpro_r1(i).Centroid(1), cpro_r1(i).Centroid(2)+cpro_r1(i).BoundingBox(4)/4],...
                                'BoundingBox', [cpro_r1(i).BoundingBox(1) cpro_r1(i).Centroid(2) cpro_r1(i).BoundingBox(3) cpro_r1(i).BoundingBox(4)/2]);
            
            cpro_r1=[cpro_r1;temp_struct1;temp_struct2];
            cpro_r1(i).Area=-1;
            %lb_r1(int16(cpro_r1(i).Centroid(2)),:)=0;
        end
    end
end
% cpro_r1=regionprops(lb_r1,'Centroid','Area','Orientation','BoundingBox');
% the number of person in region 1
pcnt_r1=size(cpro_r1,1);
%
[row col]=size(imr1t);
for i=1:row
    for j=1:col
        if (imr1t(i,j)>0)
            im_c(i+r1(3),j+r1(1),1)=219;
        end           
    end
end


temp_r1=[];

%filtered with area
%orignal setting
%limit_area=300;
%the minimum area of region that can be seen as an object
limit_area=3700;
split_area=3700;
for i=1:pcnt_r1
    if (cpro_r1(i).Area>limit_area)
            temp_r1=[temp_r1; ...
                [cpro_r1(i).Centroid(1) cpro_r1(i).Centroid(2) cpro_r1(i).Area 0 i]];
    end
end   

pcnt_r1=size(temp_r1,1);
%%
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
    
    for i=1:r1_cnt
        % double match
        if (sort_o(sort_t(i))==i)
            r1_obj(i,1:2)=0.5*temp_r1(sort_t(i),1:2)+0.5*r1_obj(i,1:2);
            r1_obj(i,3)=temp_r1(sort_t(i),3);
            r1_obj(i,5)=1;
            temp_r1(sort_t(i),4)=1;
            
        else
            
            

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
           %dis_enter=80 140;
           dis_enter=180;
           dis_enter_y=80;
           if (temp_r1(i,2)<dis_enter && temp_r1(i,1)<dis_enter_y)
              dis1=pdist2(r1_obj(:,1:2),temp_r1(i,1:2),'euclidean');
              if min(dis1)>=50
                  py1=max(1,temp_r1(i,2)-30);
                  py2=min(region_pos2(4),temp_r1(i,2)+30);
                  temp_bin=im_channel(py1:py2,1:end);
                  [bx,by]=size(temp_bin);
                  temp_bin(int16(bx/2)-20:int16(bx/2)+20,int16(by/2)-30:int16(by/2)+30,:)=0;
                  c = normxcorr2(template_bin2,temp_bin);
                  max_c=max(c(:));
                  if max_c<0.6
                      continue;
                  end
                  r1_cnt=r1_cnt+1;
                  r1_obj=[r1_obj;temp_r1(i,1:3) r1_lb+1 1];
                  
                  %% detect the correlation with empty bin so that that can be detected as new one
                   c = normxcorr2(template,im_channel(py1:py2,1:end));
%                 figure;
%                 imshow(c,[]);
                  [ypeak, xpeak] = find(c==max(c(:)));
                  yoffSet = ypeak-int16(size(template,1)/2);
                  xoffSet = xpeak-int16(size(template,2)/2);
                  dis2=pdist2(r1_obj(:,1:2),[xoffSet(1) yoffSet(1)],'euclidean');
                  no=find(dis2==min(dis2));
                  %% use the sum of edge to find the region with the min edge
%                   blob=zeros(1,r1_cnt);
%                     edge_im=edge(im_channel,'canny',0.25);
%                     for b_n=1:r1_cnt
%                         x1=max(1,round(r1_obj(b_n,2)-35));
%                         x2=min(r1(4),round(r1_obj(b_n,2)+35));
%                         blob(b_n)=sum(sum(edge_im(x1:x2,:)));
%                     end
%                     no_edge=find(blob==min(blob));
                  %%
                  if(no~=size(r1_obj,1)) %&& no_edge~=size(r1_obj,1))
                      no_2=find(dis1==min(dis1));
                      temp_center=r1_obj(no_2(1),1:3);
                      r1_obj(no_2(1),1:3)=temp_r1(i,1:3);
                      r1_obj(end,1:3)=temp_center;
                  end
                  temp_r1(i,4)=1;
                  r1_lb=r1_lb+1;
              end
           end           
        end
    end
    
    
%    detect exiting
    dis_exit=220;
    for i=1:r1_cnt
      % if (r1_obj(i,5)==0)
            if (r1_obj(i,2)>=dis_exit)
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
    limit_area=4000;
    %dis_enter=80 140;
    dis_enter=180;
    dis_enter_y=80;
    if (temp_r1(q,2)<dis_enter && temp_r1(q,1)<dis_enter_y && temp_r1(q,3)>limit_area)
        %find the maximum area of the temp region
        py1=max(1,temp_r1(q,2)-30);
        py2=min(region_pos2(4),temp_r1(q,2)+30);
        temp_bin=im_channel(py1:py2,1:end);
        [bx,by]=size(temp_bin);
        temp_bin(int16(bx/2)-20:int16(bx/2)+20,int16(by/2)-30:int16(by/2)+30,:)=0;
        c = normxcorr2(template_bin2,temp_bin);
        max_c=max(c(:));
        if max_c>0.6
            r1_cnt=1;
            r1_obj(1,:)=[temp_r1(q,1:3) 1 1]; 
            r1_lb=1;
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
% for i=1:r1_cnt
%     r1_obj(i,4)=r1_cnt-i+1;
% end
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
if n_im>12000
    break;
end
end
close(outputVideo);

