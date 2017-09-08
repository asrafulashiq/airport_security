function image=displayimage(im_c,R1,R4,people_seq,bin_seq)
r1_obj = R1.r1_obj;
r1_cnt = R1.r1_cnt;
r1 = R1.r1;
r4_obj = R4.r4_obj;
r4_cnt = R4.r4_cnt;
r4 = R4.r4;
font_size=15;
figure_handle = figure(1);
%%set the text to show the seuqence
text_im=im_c;
text_im=uint8(ones(size(im_c))*255);
imshow([im_c text_im]);
hold on;
wintx = 35;
winty = 25;

if r4_cnt>=1
    for i=1:r4_cnt
        px = r4_obj(i,1)+r4(1);
        py = r4_obj(i,2)+r4(3);
        plot(px,py,'+','color',[ 1 1 1 ],'linewidth',2);
        text(px+6,py+6,['b' num2str(r4_obj(i,4))],'color',[ 1 1 1 ],'FontSize',font_size);
        text(px+6,py-15,['p' num2str(r4_obj(i,6))],'color',[ 1 1 0 ],'FontSize',font_size);
        plot(px + [wintx+.5 -(wintx+.5) -(wintx+.5) wintx+.5 wintx+.5],py + [winty+.5 winty+.5 -(winty+.5) -(winty+.5)  winty+.5],'-','color',[ 1 1 1 ],'linewidth',2);
    end
end

wintx = 30;
winty = 30;

if r1_cnt >= 1
    for i = 1:r1_cnt
        px = r1_obj(i,1) + r1(1);
        py = r1_obj(i,2) + r1(3);
        plot(px,py,'+','color',[ 1 1 1 ],'linewidth',2);
        text(px+6,py+6,['p' num2str(r1_obj(i,4))],'color',[1 1 1],'FontSize',font_size);
        plot(px + [wintx+.5 -(wintx+.5) -(wintx+.5) wintx+.5 wintx+.5],py + [winty+.5 winty+.5 -(winty+.5) -(winty+.5)  winty+.5],'-','color',[ 1 1 1 ],'linewidth',2);
    end
end

%%show text
tx=size(im_c,2)+30;
ty=50;
text(tx,ty,'p-seq','color',[0 0 0],'FontSize',font_size);
for i=1:size(people_seq,1)
    text(tx,ty+i*18,['p' num2str(people_seq(i,4))],'color',[0 0 0],'FontSize',font_size);
end
tx=size(im_c,2)+90;
text(tx,ty,'b-seq','color',[0 0 0],'FontSize',font_size);
for i=1:size(bin_seq,1)
    if i>=22
        text(tx+60,ty+(i-22)*18,['b' num2str(bin_seq(i,4)) ' p' num2str(bin_seq(i,6))],'color',[0 0 0],'FontSize',font_size);
    else
        text(tx,ty+i*18,['b' num2str(bin_seq(i,4)) ' p' num2str(bin_seq(i,6))],'color',[0 0 0],'FontSize',font_size);
    end
end
% %% draw separate line
% lx=[266, 351];
% ly=[1 472];
% dis1=100;
% plot(lx,(1.0e+03)*(0.0055*(lx)-1.4730)+dis1,'r-');
% plot([1 size(im_c,2)],[420 420],'r-');
%% draw now
drawnow;
set(gcf, 'position', [0 0 size([im_c text_im],2)*2 size([im_c text_im],1)*2]);
hold off;
F = getframe(gcf);
image=F.cdata;
end