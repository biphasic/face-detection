function subset = crop_spatial(recording, left, bottom, width, heigth)
    %logical mask
    mask = and(and(recording.x>=left, recording.x<(left+width)), and(recording.y>=bottom, recording.y<(bottom+heigth)));

    %struct fields
    fields = fieldnames(recording);

    for i = 1:numel(fields)
        subset.(fields{i}) = recording.(fields{i})(mask);
    end

end