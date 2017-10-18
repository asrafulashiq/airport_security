function full_file_name = get_CLASP_file_name(video_no, camera_no, frame_no)


if frame_no < 10
    str = ['000',num2str(frame_no)];
end
if frame_no >= 10 && frame_no < 100
    str = ['00',num2str(frame_no)];
end
if frame_no >= 100 && frame_no < 1000
    str = ['0',num2str(frame_no)];
end
if frame_no >= 1000
    str = num2str(frame_no);
end

main_dir ='/Users/ashrafulislam/Box Sync/Documents/airport thesis/airport_security/camera9/CLASP_labeling/CLASP_labels/';
video_dir_name = [video_no , '_C', camera_no];
frame_file_name = ['Frame', str,'.jpg.txt' ];

full_file_name = fullfile(main_dir, video_dir_name, frame_file_name);

 if exist(full_file_name) == 0
    error('FILE does not exist'); 
 end

end