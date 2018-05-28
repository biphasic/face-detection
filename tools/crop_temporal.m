function subset = crop_temporal(recording, start, fin)
    mask = and(recording.ts >= start, recording.ts <= fin);

    %struct fields
    fields = fieldnames(recording);

    for i = 1:numel(fields)
        subset.(fields{i}) = recording.(fields{i})(mask);
    end

end