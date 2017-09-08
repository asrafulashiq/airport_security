clear all;
%%
filename='out.avi';
v = VideoReader(filename);
se = strel('disk',10);
h = fspecial('gaussian',[5,5], 2);   
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


% im_p2=imread('ims1.jpg');
% im_p(r4(3):r4(4),r4(1):r4(2),:)=im_p2(r4(3):r4(4),r4(1):r4(2),:);



im_r1_p=im_p(r1(3):r1(4),r1(1):r1(2),:);



%object information for each region
r1_obj=[];
imrrr1=[];


%object count for each region
r1_cnt=0;

%Object Labels
r1_lb=0;

%fig_handle2=figure(2);



speed=1;
for n_im=start_f:speed:end_f

%resize to speed up

im_c = imresize(read(v,n_im),0.25);
im_c = imrotate(im_c, -90);
n_im


im_r1=im_c(r1(3):r1(4),r1(1):r1(2),:);
imfn=im_r1;
im_r1=abs(im_r1_p-im_r1)+abs(im_r1-im_r1_p);

%im_r1=im_r1./im_r1_p;

imr1eqc=0.33*(im_r1(:,:,1)+im_r1(:,:,1)+im_r1(:,:,1));




imr1eq=histeq(imr1eqc);





imr1t=imr1eq;

pt1=[];
pt2=[];
stp=10;
end_step=size(imr1t,1);
for i=1+stp:(end_step-stp)
    pt1(i)=var(var(double(imr1t(i-stp:i+stp,:))));
    pt2(i)=mean(mean(imr1t(i-stp:i+stp,:)));
end
pt1=medfilt1(pt1,stp);

thpt1=max(pt1)/2;
meanpt2=mean(pt2);

imr1t(1:stp,:)=0;
imr1t(end_step-stp:end,:)=0;

threshold=150;
for i=1+stp:(end_step-stp)
    if ((pt2(i)>threshold))
        imr1t(i,:)=1;
    else
        imr1t(i,:)=0;
    end
end



lb_r1=bwlabel(imr1t);
cpro_r1=regionprops(lb_r1,'Centroid','Area','BoundingBox');



pcnt_r1=size(cpro_r1,1);
temp_r1=[];
%filtered with area
limited_area=3500;
limited_area=3500;
for i=1:pcnt_r1
    if (cpro_r1(i).Area>limited_area)
    srcnt=round(cpro_r1(i).Area/limited_area);
     if (srcnt<=1)
     temp_r1=[temp_r1; [cpro_r1(i).Centroid(1) cpro_r1(i).Centroid(2) cpro_r1(i).Area 0 i]];
     else
        sublng=cpro_r1(i).Area/42;
        for j=1:srcnt
        temp_r1=[temp_r1; [cpro_r1(i).Centroid(1) cpro_r1(i).Centroid(2)-(0.5*sublng-(j*2-1)*sublng/srcnt/2) cpro_r1(i).Area 0 i]];
        end
        
     end
    
    end
end   

pcnt_r1=size(temp_r1,1);



imrrr1=label2rgb(lb_r1);



im4_b=im2bw(im_r1,0.18);
im4_b=imfilter(im4_b,h);


se = strel('disk',10);
im4_b=imclose(im4_b,se);

im4_b=double(im4_b);

imrrr2(:,:,1)=im4_b*255;
imrrr2(:,:,2)=im4_b*255;
imrrr2(:,:,3)=im4_b*255;

       

figure(1)
hold on;
imshow([imfn im_r1 imrrr1]);






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
    
    
    
    
    
    
    
    
    
    
    
    % detect entering
    for i=1:pcnt_r1
        if (temp_r1(i,4)==0)
           if ((r1(2)-r1(1)-temp_r1(i,1))<50)
                  r1_cnt=r1_cnt+1;
                  r1_obj=[r1_obj;temp_r1(i,1:3) r1_lb+1 1];  
                  temp_r1(i,4)=1;
                  r1_lb=r1_lb+1;
           end           
        end
    end
    
    
%    detect exiting

    for i=1:r1_cnt
      % if (r1_obj(i,5)==0)
            if (r1(4)-r1(3)-r1_obj(i,2)<30)
                   r1_obj(i:end-1,:)=r1_obj(i+1:end,:);
                   r1_cnt=r1_cnt-1;
                   r1_obj=r1_obj(1:r1_cnt,:);
                   disp('delete!');
                   break
            end
       % end
    
    end
   
    
 else    
    
    %add only one object with the maximum area
    max_pos=find(temp_r1(:,3)==max(temp_r1(:,3)));
    for i=1:size(max_pos,1)
        r1_cnt=r1_cnt+1;
        r1_obj(i,:)=[temp_r1(max_pos(i),1:3) 1 1]; 
        r1_lb=r1_lb+1;
    end
 end


end













wintx=20;
winty=20;
for i=1:r1_cnt
    
    px=r1_obj(i,1);
    py=r1_obj(i,2);  
    plot(px,py,'+','color',[ 1 1 1 ],'linewidth',2);
    text(px+6,py+6,['b' num2str(r1_obj(i,4))],'color',[ 1 1 1 ]);

    plot(px + [wintx+.5 -(wintx+.5) -(wintx+.5) wintx+.5 wintx+.5],py + [winty+.5 winty+.5 -(winty+.5) -(winty+.5)  winty+.5],'-','color',[ 1 1 1 ],'linewidth',2);

end


hold off;




end



return




[row col d]=size(im_c);




%result for region 1
[row col]=size(im2_b);
for i=1:row;
    for j=1:col;
        if (im2_b(i,j)==1)
            imfn(i,j,1)=219;
        end           
    end
end

lb_r1=bwlabel(im2_b);
cpro_r1=regionprops(lb_r1,'Centroid','Area','Orientation','BoundingBox');
pcnt_r1=size(cpro_r1,1);


temp_r1=[];

%filtered with area
for i=1:pcnt_r1
    if (cpro_r1(i).Area>300)
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
            elseif (dis_r1(i,sort_t(i))<120)
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
    
    
    
    
    
    
    
    
    
    
    
    % detect entering
    for i=1:pcnt_r1
        if (temp_r1(i,4)==0)
           if ((r1(2)-r1(1)-temp_r1(i,1))<50)
                  r1_cnt=r1_cnt+1;
                  r1_obj=[r1_obj;temp_r1(i,1:3) r1_lb+1 1];  
                  temp_r1(i,4)=1;
                  r1_lb=r1_lb+1;
           end           
        end
    end
    
    
%    detect exiting

    for i=1:r1_cnt
      % if (r1_obj(i,5)==0)
            if (r1(4)-r1(3)-r1_obj(i,2)<50)
                   r1_obj(i:end-1,:)=r1_obj(i+1:end,:);
                   r1_cnt=r1_cnt-1;
                   r1_obj=r1_obj(1:r1_cnt,:);
                   disp('delete!');
                   break
            end
       % end
    
    end
   
    
 else    
    r1_cnt=1;
    %add only one object with the maximum area
    r1_obj(1,:)=[temp_r1(find(temp_r1(:,3)==max(temp_r1(:,3))),1:3) 1 1]; 
    r1_lb=1;
 end
 
 
    
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DISPLAY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure_handle=figure(1);
if (rem(n_im,1)==0)
%if(1)
%imshow(imfn);



imrrr1(:,:,1)=imr1eq;
imrrr1(:,:,2)=imr1eq;
imrrr1(:,:,3)=imr1eq;

imshow([imfn im_r1 imrrr1]);

hold on;


   
wintx=30;
winty=30;
for i=1:r1_cnt
    
    px=r1_obj(i,1);
    py=r1_obj(i,2);  
    plot(px,py,'+','color',[ 1 1 1 ],'linewidth',2);
    text(px+6,py+6,['p' num2str(r1_obj(i,4))],'color',[ 1 1 1 ]);
    
    plot(px + [wintx+.5 -(wintx+.5) -(wintx+.5) wintx+.5 wintx+.5],py + [winty+.5 winty+.5 -(winty+.5) -(winty+.5)  winty+.5],'-','color',[ 1 1 1 ],'linewidth',2);

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
%print(figure_handle,'-djpeg','-noui',['I:\\20110124\im' num2str(n_im) '.jpg']);

 %dis_r1
  %input('press enter');
% % 
%  temp_r1
%  r1_obj
 
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%end
