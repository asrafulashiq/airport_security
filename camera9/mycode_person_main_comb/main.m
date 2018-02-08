% init all
R_all = [];
R_all.check_2 = 0;

file_number = '7A';
start_frame = 300;


%% work with 9 and 2
main_9_init;
main_2_init;

%run 1 loop of 9
while true
    
    main_2_loop;
    
    main_9_loop;
    
    % now check
    
    
end
%% save data
if R_2.write
    close(R_2.writer);
end

if R_2.save_info
    save(R_2.file_save_info, 'R_2');
end

if R_9.write
    close(R_9.writer);
end

if R_9.save_info
    save(R_9.file_save_info, 'R_9');
end

%% work with 5,11,13
%main_5_init;
% R_11.R_bin.check = 1;
% R_11.R_people.check = 1;
% R_13.R_bin.check = 0;
% R_13.R_people.check = 0;
% 
% R_11.R_bin.check_del = 0;
% R_11.R_people.check_del = 0;
% R_13.R_bin.check_del = 0;
% R_13.R_people.check_del = 0;
% 
% 
% main_11_init;
% main_13_init;
% 
% % loop
% while true
%    
%    main_11_loop;
%    
%    main_13_loop;
%     
%     
% end
% 
% 
% if R_11.write
%     close(R_11.writer1);
%     close(R_11.writer2);
% end
% 
% if R_11.save_info
%     save(R_11.file_save_info, 'R_11');
% end
% 
% if R_13.write
%     close(R_13.writer);
% end
% 
% if R_13.save_info
%     save(R_13.file_save_info, 'R_13');
% end


