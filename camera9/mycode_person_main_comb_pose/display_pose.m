function im = display_pose(im, R_11)

global scale;
crop =  [ 230  150  730  1738]*scale;
% Img = imcrop(im, crop);
Img = im;

load('E:\alert_remote_code\airport_security\camera9\mycode_person_main_comb_pose\clasp_pose\Result_09C11.mat');

Result = Result_09C11;

frame_no = R_11.current_frame;
i = frame_no + 65;

limbSeq =  [2 3; 2 6; 3 4; 4 5; 6 7; 7 8; 2 9; 9 10; 10 11; 2 12; 12 13; 13 14; 2 1; 1 15; 15 16; 15 18; 17 6; 6 3; 6 18];
colors = hsv(length(limbSeq));
facealpha = 0.6;
stickwidth = 4;
joint_color = [255, 0, 0;  255, 85, 0;  255, 170, 0;  255, 255, 0;  170, 255, 0;   85, 255, 0;  0, 255, 0;  0, 255, 85;  0, 255, 170;  0, 255, 255;  0, 170, 255;  0, 85, 255;  0, 0, 255;   85, 0, 255;  170, 0, 255;  255, 0, 255;  255, 0, 170;  255, 0, 85];
candidates = Result(i).candi;
subset = Result(i).sub;
% finding joints for each person
for num = 1:size(subset,1)
    %imshow(image);
    for ii = 1:18
        index = subset(num,ii);
        if index == 0
            continue;
        end
        X = candidates(index,1) + crop(1);
        Y = candidates(index,2) + crop(2);
        Img = insertShape(Img, 'FilledCircle', [X Y 8], 'Color', joint_color(ii,:));
    end
end
f = figure(20);

imshow(Img),hold on

% plot for each part
for k = 15:18
    for num = 1:size(subset,1)
        index = subset(num,limbSeq(k,1:2));
        if sum(index==0)>0
            continue;
        end
        X = candidates(index,1) + crop(1);
        Y = candidates(index,2) + crop(2);
        
        if(~sum(isnan(X)))
            mX = mean(X);
            mY = mean(Y);
            [~,~,V] = svd(cov([X-mX Y-mY]));
            v = V(2,:);
            
            pts = [X Y];
            pts = [pts; pts + stickwidth*repmat(v,2,1); pts - stickwidth*repmat(v,2,1)];
            A = cov([pts(:,1)-mX pts(:,2)-mY]);
            if any(X)
                he(i) = filledellipse(A,[mX mY],colors(k,:),facealpha);
            end
        end
    end
    
end

% im(crop(2):crop(2)+crop(4), crop(1):crop(1)+crop(3), :) = Img;
im = getframe(f);
im = im.cdata;

end