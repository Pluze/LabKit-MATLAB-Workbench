% Expected caller: ecg_print direct callbacks and direct unit tests. Inputs are a
% file path and maximum line count. Output is a column cell array of display
% lines. Side effects: reads the requested file only.

function lines = previewFileHeader(filepath, maxLines)
%PREVIEWFILEHEADER Return numbered header preview lines for the ECG Print app.

    lines = {};
    fid = fopen(filepath, 'r');
    if fid < 0
        lines = {'Could not open file preview.'};
        return;
    end
    cleaner = onCleanup(@() fclose(fid));
    for k = 1:maxLines
        line = fgetl(fid);
        if ~ischar(line)
            break;
        end
        lines{end+1, 1} = sprintf('%02d: %s', k, line);
    end
    if isempty(lines)
        lines = {'File is empty or could not be previewed.'};
    end
end
