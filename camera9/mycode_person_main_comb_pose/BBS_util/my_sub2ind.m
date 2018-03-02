function idx = my_sub2ind(siz, rows, cols)

idx = rows + (cols-1)*siz(1);