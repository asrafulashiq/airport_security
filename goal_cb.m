function err=goal_cb(kin,tbar,b_num)

%1. minimize the sum
k=round(kin*0.01*(size(tbar,1)));
k2=kin-round(k);
sum_bar=0;
err=[];
for i=1:b_num
    if k(i)<16
        k(i)=16;
    elseif k(i)>(size(tbar,1)-15)
        k(i)=size(tbar,1)-15;
    end
    
    err=[err 300000-sum(tbar(k(i)-15:k(i)+15))+k2(i)];
end;


;

        