function seq = report_tracking_result(seq, result)

    seq.rect_position(seq.frame,:) = round([result.center_pos([2,1]) - (result.target_size([2,1]) - 1)/2, result.target_size([2,1])]);
end