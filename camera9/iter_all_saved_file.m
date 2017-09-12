
all_file_nums = ["5A_take1","5A_take2","5A_take3","6A","9A","10A"];

for file_number_str = all_file_nums
    file_number = char(file_number_str); % convert to character array
    
    file_to_save = fullfile(file_number, ['camera9_' file_number '_vars.mat']);
    m = matfile(file_to_save,'Writable',true );
    m.start_f = 100;
    
    
end