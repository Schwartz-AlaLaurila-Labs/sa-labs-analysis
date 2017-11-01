function savedFileName = sandbox(file, cellLabel)
    [match, ~] = regexp(cellLabel, '[0-9]+' ,'match','split');
    if ~ isempty(match)
        savedFileName = [file 'c' match{:}];
    else 
        savedFileName = file;
    end
end

