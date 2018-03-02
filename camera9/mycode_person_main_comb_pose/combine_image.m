function image = combine_image(i1, i2, i3, i4)

[r,c,d] = size(i2);

if isempty(i1)
    i1 = uint8(zeros(r,c,d));
end

if isempty(i2)
    i2 = uint8(zeros(r,c,d));
end

if isempty(i3)
    i3 = uint8(zeros(r,c,d));
end

if isempty(i4)
    i4 = uint8(zeros(r,c,d));
end


i3 = imresize(i3, [r c]);
i4 = imresize(i4, [r c]);
image = [i1 i2 i3 i4];

end