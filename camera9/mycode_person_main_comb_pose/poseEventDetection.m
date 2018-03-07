function event = poseEventDetection(im, R_11)
global scale;
crop =  [ 230  150  730  1738]*scale;
% Img = imcrop(im, crop);
Img = im;

event = [];

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

% set head to person id


%
head_ind = find(candidates(:, 4) == 1.0);

if isempty(head_ind)
   return; 
end

for index = head_ind'
    
    % assign head to person
    X = candidates(index,1) ;
    Y = candidates(index,2) ;
    
    people = R_11.R_people.people_array;
    p_ind = -1;
    for j = 1:numel(people)
        if Y >= people{j}.BoundingBox(2) && Y<= people{j}.BoundingBox(2)+people{j}.BoundingBox(4)
            p_ind = j;
        end
    end
    if p_ind == -1
        continue;
    end
    
    % get hand co-ord of the people : 3, 18
    right_wrist_ind = find(candidates(:, 4) == 3.0);
    
    min_ = [inf -1 inf inf];
    
    for k = right_wrist_ind'
        rx = candidates(k,1) ;
        ry = candidates(k,2) ;
        
%         centre = people{p_ind}.Centroid + [R_11.R_people.reg(1); R_11.R_people.reg(3)];
        dis = norm( [X;Y]- [rx; ry] );
        
        if dis < 200 && dis < min_(1)
            min_ = [dis k rx ry];
        end
    end
    
    right_wrist = min_(3:4)+ crop(1:2);
    
    
    left_wrist_ind = find(candidates(:, 4) == 18.0);
    min_ = [inf -1 0 0];
    for k = left_wrist_ind'
        lx = candidates(k,1);
        ly = candidates(k,2);
        
        centre = people{p_ind}.Centroid + [R_11.R_people.reg(1); R_11.R_people.reg(3)];
        
        dis = norm( [X;Y]- [lx; ly] );
        
        if dis < 200 && dis < min_(1)
            min_ = [dis k lx ly];
        end
    end
    
    left_wrist = min_(3:4) + crop(1:2);
    
    %% check waving over other people's bins
    bin_array = R_11.R_bin.bin_array;
    if ~isinf(left_wrist(1))
        lx = left_wrist(1); ly = left_wrist(2);
        
        for l = 1:numel(R_11.R_bin.bin_array)
            bb = [ bin_array{l}.BoundingBox(1) + R_11.R_bin.reg(1) ...
                bin_array{l}.BoundingBox(2) + R_11.R_bin.reg(3) ...
                bin_array{l}.BoundingBox(3) ...
                bin_array{l}.BoundingBox(4) ];
            if inpoint(lx, ly, bb)
                if bin_array{l}.belongs_to ~= people{p_ind}.label
                   % event id 3 happend
                   event = [ 3 people{p_ind}.label bin_array{l}.label 1];
                else
                    event = [ 4 people{p_ind}.label bin_array{l}.label 1];
                end
            end
            
        end
    end
    
    if ~isinf(right_wrist(1))
        lx = right_wrist(1); ly = right_wrist(2);
        
        for l = 1:numel(R_11.R_bin.bin_array)
            bb = [ bin_array{l}.BoundingBox(1) + R_11.R_bin.reg(1) ...
                bin_array{l}.BoundingBox(2) + R_11.R_bin.reg(3) ...
                bin_array{l}.BoundingBox(3) ...
                bin_array{l}.BoundingBox(4) ];
            if inpoint(lx, ly, bb)
                if bin_array{l}.belongs_to ~= people{p_ind}.label
                   % event id 3 happend
                   event = [ 3 people{p_ind}.label bin_array{l}.label bin_array{l}.belongs_to];
                else
                    event = [ 4 people{p_ind}.label bin_array{l}.label 1];
                end
            end
            
        end
    end
    
    
end



