close all
%writerObj = VideoWriter('Camera11.avi');
%writerObj.FrameRate = 1;
%open(writerObj);
Result = Result_09C11;
secsPerImg = 5;

crop = containers.Map;
scale = 0.5;
crop('09_5AC9') =  [660  336   730  1738]*scale;
crop('09_5AC11') =  [ 230  150  730  1738]*scale;
rotation = containers.Map;
rotation('09_5AC9') = 102;
rotation('09_5AC11') = 90;
type = '09_5AC11';

for i = 2150 : length(Result)
    
    frame_no = i-65;
    full_path = ['E:\shared_folder\all_videos\9A\11\' sprintf('%04d.jpg',frame_no) ];
    disp(['frame : ' num2str(frame_no)]);
%     Img = imread(Result(i).imPath);    
    img = imread(full_path);
    img = imresize(img,scale);
    img = imrotate(img, rotation(type));
    Img = imcrop(img, crop(type));
    
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
            X = candidates(index,1);
            Y = candidates(index,2);
            Img = insertShape(Img, 'FilledCircle', [X Y 5], 'Color', joint_color(ii,:)); 
        end
    end
    imshow(Img),hold on
    
    % plot for each part
        for k = 15:18 
            for num = 1:size(subset,1)      
                index = subset(num,limbSeq(k,1:2));
                if sum(index==0)>0
                    continue;
                end
                X = candidates(index,1);
                Y = candidates(index,2);

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
        
        %export_fig(['video/connect_' num2str(i) '.png']);
        end
    
   pause(0.05); 
   frame = getframe(gcf);
   drawnow;
   
   %writeVideo(writerObj, frame);
    
    %{
    for ii = 1 : length(candidate)
        
        plot(candidate(ii,1),candidate(ii,2),'r*');
     
        1;
      
    end
    %}
    
    
end
%close(writerObj);

