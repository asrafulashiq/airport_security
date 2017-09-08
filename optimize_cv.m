clc
k_Est=[10 50 90];
k=k_Est;
options = optimset('LargeScale','on','LevenbergMarquardt','on','MaxIter', 10000,'MaxFunEvals',100000);
%[x,resnorm,residual,exitflag,output]  = lsqnonlin( @goal_cb, k,[1 1 1],[100 100 100],options,tbar,3)

x=fminsearch(@goal_cb, k,options,tbar,k_num)