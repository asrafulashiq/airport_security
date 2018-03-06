function obj = setPos(obj, pos, ind)

if nargin < 3 ||  isempty(ind)
    obj.data.pos = pos([2 1]);
    
elseif ind==1 % x val
    obj.data.pos(2) = pos;
else % y val
    obj.data.pos(1) = pos;
end