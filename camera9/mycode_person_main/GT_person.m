function bbox = GT_person(file_number, frame_number, obj_type)
bbox = [];
i = frame_number;
rate = 30;
if i < 10
    str = ['000',num2str(i)];
end
if i >= 10 && i < 100
    str = ['00',num2str(i)];
end
if i >= 100 && i < 1000
    str = ['0',num2str(i)];
end
if i >= 1000
    str = num2str(i);
end
if mod(i,rate) == 0
    filename = fullfile('..','EXPERIMENT_9A','camera_9' ,['Frame',str,'.jpg.txt'] );
end

if ~exist(filename)
   return []; 
end

fid = fopen(filename, 'r');
while ~feof(fid)
    line = fgetl(fid);
    
    if strfind(line, obj_type)
        ll = split(line);
        bbox = [bbox; [ ll{2} ll{3} ll{4} ll{5} ]];
    end
    
end

end