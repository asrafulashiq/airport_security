classdef BACF_tracker
   
    properties
        data
    end
    
    methods
        
        function obj = BACF_tracker(im, rect)
            seq.im = im;
            seq.init_rect = rect;
           obj = obj.setParams(seq); 
        end
        
        obj = setParams(obj, seq)
        
        obj = setInit(obj,im, rect)
        
        [obj, rect] = runTrack(obj, im)
        
        obj = setPos(obj, pos, ind)
        
        pos = getPos(obj)
        
        obj = setRect(obj, r)
        
    end
    
end