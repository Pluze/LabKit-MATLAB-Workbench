% Expected caller: ecg_print direct callbacks and direct unit tests. Inputs are a
% file path and maximum line count. Output is a column cell array of display
% lines. Side effects: reads supported delimited-text files only.

function lines = previewFileHeader(filepath, maxLines)
%PREVIEWFILEHEADER Return numbered header preview lines for the ECG Print app.

    [~, ~, extension] = fileparts(char(filepath));
    textExtensions = {'.csv', '.txt', '.tsv'};
    if ~any(strcmpi(extension, textExtensions))
        lines = {'Header preview is available only for delimited text recordings.'};
        return;
    end

    fid = fopen(filepath, 'r');
    if fid < 0
        lines = {'Could not open file preview.'};
        return;
    end
    cleaner = onCleanup(@() fclose(fid));
    % Keep malformed single-line text from becoming an unbounded UI payload.
    previewByteLimit = 64 * 1024;
    maxCharactersPerLine = 240;
    bytes = fread(fid, previewByteLimit, '*uint8');
    text = char(bytes(:).');
    rawLines = regexp(text, '\r\n|\n|\r', 'split');
    if ~isempty(rawLines) && isempty(rawLines{end})
        rawLines(end) = [];
    end
    lineCount = min(maxLines, numel(rawLines));
    lines = cell(lineCount, 1);
    for k = 1:lineCount
        line = rawLines{k};
        if numel(line) > maxCharactersPerLine
            line = [line(1:maxCharactersPerLine), ' ... [truncated]'];
        end
        lines{k, 1} = sprintf('%02d: %s', k, line);
    end
    if isempty(lines)
        lines = {'File is empty or could not be previewed.'};
    end
end
