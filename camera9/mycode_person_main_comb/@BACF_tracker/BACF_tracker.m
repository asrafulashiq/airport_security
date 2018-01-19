classdef BACF_tracker
   
    properties
        data
    end
    
    methods
        
        function obj = BACF_tracker(seq)
           obj = obj.setParams(seq); 
        end
        
        obj = setParams(obj, seq)
        
        obj = setInit(obj,im, rect)
        
        [obj, rect] = runTrack(obj, im)
        
    end
    
end