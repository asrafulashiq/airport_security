function imm = back_sub(im, im_b, thres)

imm = im;

for i = 1:size(im,1)
    for j = 1:size(im,2)
        if mean(abs( im(i,j,:) - im_b(i,j,:) )) < thres
           imm(i,j,:) = 0; 
        end
    end
end


end