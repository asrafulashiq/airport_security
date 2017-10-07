function r = create_rect(wid, offset, val)
    
r = zeros(1,wid);
r(offset:wid-offset+1) = 1;
r = r * val;    
    
end