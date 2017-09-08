function E=fun(a,x,y) 
x=x(:); 
y=y(:); 
Y=a(1)*(1-exp(-a(2)*x)) + a(3)*(exp(a(4)*x)-1); 
E=y-Y; 
