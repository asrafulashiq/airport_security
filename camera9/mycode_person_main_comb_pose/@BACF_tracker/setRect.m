function obj = setRect(obj, rect)
    
    pos = rect([1,2]) + rect([3,4])/2 - 1;
    obj = obj.setPos(pos);
    
    obj.data.base_target_sz = rect([4,3]);
    obj.data.currentScaleFactor = 1;
    
end