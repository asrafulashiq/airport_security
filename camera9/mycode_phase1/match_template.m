function [cpro, template] = match_template(loc_something, I, template, thr)

t_struct = [];

if length(size(I))==3
    I = rgb2gray(I);
end


obj_num = size(template,2);

if obj_num == 0
    
    T_img = rgb2gray(imread('template1.jpg'));

    point_T = detectBRISKFeatures(T_img);
    
    point_I = detectBRISKFeatures( I(loc_something(1): loc_something(end), :));
    
    [featuresT,valid_pointsT] = extractFeatures(T_img,point_T);
    [featuresI,valid_pointsI] = extractFeatures(I,point_I);
    
    indexPairs = matchFeatures(featuresT,featuresI);

    matchedPointsT = valid_pointsT(indexPairs(:,1),:);

    matchedPointsI = valid_pointsI(indexPairs(:,2),:);

    
    figure; showMatchedFeatures(I,T_img,matchedPointsI,matchedPointsT);

    
end


end