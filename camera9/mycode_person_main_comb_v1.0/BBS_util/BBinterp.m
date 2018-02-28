function BBw = BBinterp(BB, szT, pz, v);

szI = size(BB);

[x,y] = meshgrid(1:pz:szI(2)-szT(2)+1, 1:pz:szI(1)-szT(1)+1);
[xx,yy] = meshgrid(1:szI(2), 1:szI(1));

Temp = BB(1:size(x,1), 1:size(x,2));
BBw = interp2(x,y, Temp,xx, yy);
BBw = MoveToCenter(BBw, szT(1:2), v);