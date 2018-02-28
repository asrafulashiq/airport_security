function [seq] = get_sequence_info( init_rect)

seq.frame = 0;

seq.init_sz = [init_rect(1,4), init_rect(1,3)];
seq.init_pos = [init_rect(1,2), init_rect(1,1)] + (seq.init_sz - 1)/2;

end