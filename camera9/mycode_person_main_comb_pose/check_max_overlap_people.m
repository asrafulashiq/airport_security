function m = check_max_overlap_people(bb, people_array, i)
m = 0;
for j = 1:numel(people_array)
    if i~=j
        rat = bboxOverlapRatio(bb,people_array{j}.BoundingBox,'Min');
        if rat > m
            m = rat;
        end
    end
end
end