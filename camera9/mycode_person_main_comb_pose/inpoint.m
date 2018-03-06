function flag = inpoint(x,y, bb)

flag = false;
if x >= bb(1) && x< bb(1)+bb(3) && y >= bb(2) && y<bb(2)+bb(4)
    flag = true;
end
end