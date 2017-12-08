function image = displayimage2(im_c, R_belt, R_dropping, bin_array, people_array, bin_seq, people_seq)
% r1_obj = R1.r1_obj;
% r1_cnt = R1.r1_cnt;
% r1 = R1.r1;
% r4_obj = R4.r4_obj;
% r4_cnt = R4.r4_cnt;
% r4 = R4.r4;
% font_size=30;


%% decorate text
font_size = 50;
text_im=uint8(ones(size(im_c, 1), floor(size(im_c, 2) * 0.6), 3) * 255);

t_width = size(text_im, 2);
t_height = size(text_im, 1);

t_pad_x = t_width * 0.05;
t_pad_y = t_height * 0.1;

b_strt_x = t_pad_x;
b_strt_y = t_pad_y;
p_strt_x = t_width / 2 + t_pad_x;
p_strt_y = t_pad_y;

font_box_height = font_size * 1.3;
text_im = insertText(text_im, [b_strt_x  b_strt_y], 'B-seq', 'AnchorPoint', 'LeftBottom', ...
    'FontSize', font_size, 'BoxOpacity', 0.3);
text_im = insertText(text_im, [p_strt_x  p_strt_y], 'P-seq', 'AnchorPoint', 'LeftBottom', ... 
    'FontSize', font_size, 'BoxOpacity', 0.3);


%%% annotate main image
%% plot bin
for i=1:size(bin_array,2)
    if bin_array{i}.in_flag==1
        
        bounding_box = [ bin_array{i}.BoundingBox(1)+R_belt.r4(1) ...
                         bin_array{i}.BoundingBox(2)+R_belt.r4(3) ...
                         bin_array{i}.BoundingBox(3) ...
                         bin_array{i}.BoundingBox(4) ];
        
        im_c = insertShape(im_c, 'FilledRectangle', bounding_box, 'Color', 'red', ...
                            'Opacity', 0.3);
        im_c = insertShape(im_c, 'Rectangle', bounding_box, 'LineWidth', 2, 'Color', 'red');
       
        
        
    end
end


%% insert text
for i = 1:size(bin_seq, 2)
    text_im = insertText(text_im, [p_strt_x+i*font_box_height  p_strt_y+i*font_box_height],...
                ['b' num2str(bin_seq{i}.label)], ...
                'AnchorPoint', 'LeftBottom', 'FontSize', font_size, 'BoxOpacity', 0.3);
end


%% plot 
figure(1);
imshow([im_c text_im]);
drawnow;

F = getframe(gcf);
image=F.cdata;

% %hold on;
% 
% % wintx = 35;
% % winty = 25;
% 
% 
% 
% if r4_cnt>=1
%     for i=1:r4_cnt
%         px = r4_obj(i,1)+r4(1);
%         py = r4_obj(i,2)+r4(3);
%         plot(px,py,'+','color',[ 1 1 1 ],'linewidth',2);
%         text(px+6,py+6,['b' num2str(r4_obj(i,4))],'color',[ 1 1 1 ],'FontSize',font_size);
%         text(px+6,py-15,['p' num2str(r4_obj(i,6))],'color',[ 1 1 0 ],'FontSize',font_size);
%         plot(px + [wintx+.5 -(wintx+.5) -(wintx+.5) wintx+.5 wintx+.5],py + [winty+.5 winty+.5 -(winty+.5) -(winty+.5)  winty+.5],'-','color',[ 1 1 1 ],'linewidth',2);
%     end
% end
% 
% wintx = 30;
% winty = 30;
% 
% if r1_cnt >= 1
%     for i = 1:r1_cnt
%         px = r1_obj(i,1) + r1(1);
%         py = r1_obj(i,2) + r1(3);
%         plot(px,py,'+','color',[ 1 1 1 ],'linewidth',2);
%         text(px+6,py+6,['p' num2str(r1_obj(i,4))],'color',[1 1 1],'FontSize',font_size);
%         plot(px + [wintx+.5 -(wintx+.5) -(wintx+.5) wintx+.5 wintx+.5],py + [winty+.5 winty+.5 -(winty+.5) -(winty+.5)  winty+.5],'-','color',[ 1 1 1 ],'linewidth',2);
%     end
% end
% 
% %%show text
% tx=size(im_c,2)+30;
% ty=50;
% text(tx,ty,'p-seq','color',[0 0 0],'FontSize',font_size);
% for i=1:size(people_seq,1)
%     text(tx,ty+i*18,['p' num2str(people_seq(i,4))],'color',[0 0 0],'FontSize',font_size);
% end
% tx=size(im_c,2)+90;
% text(tx,ty,'b-seq','color',[0 0 0],'FontSize',font_size);
% for i=1:size(bin_seq,1)
%     if i>=22
%         text(tx+60,ty+(i-22)*18,['b' num2str(bin_seq(i,4)) ' p' num2str(bin_seq(i,6))],'color',[0 0 0],'FontSize',font_size);
%     else
%         text(tx,ty+i*18,['b' num2str(bin_seq(i,4)) ' p' num2str(bin_seq(i,6))],'color',[0 0 0],'FontSize',font_size);
%     end
% end
% %% draw separate line
% lx=[266, 351];
% ly=[1 472];
% dis1=100;
% plot(lx,(1.0e+03)*(0.0055*(lx)-1.4730)+dis1,'r-');
% plot([1 size(im_c,2)],[420 420],'r-');
% %%draw now
% drawnow;
% set(gcf, 'position', [0 0 size([im_c text_im],2)*2 size([im_c text_im],1)*2]);
% hold off;
% F = getframe(gcf);
% image=F.cdata;

end