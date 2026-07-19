% Expected caller: RHS Preview direct callbacks and unit tests. Inputs are one root folder
% or a string list of RHS task files plus optional previous filter rows.
% Output is the RHS file list with user labels/comments preserved by file
% path. No QC is performed.
function rows = discoverFilterRows(rootDirOrFiles, previousRows)
%DISCOVERFILTERROWS Build editable RHS file filter rows.

    if nargin < 2 || isempty(previousRows)
        previousRows = table();
    end

    files = discoverFiles(rootDirOrFiles);
    nFiles = numel(files);
    recordingId = "R" + compose("%03d", (1:nFiles).');
    filePath = files(:);
    label = repmat("good", nFiles, 1);
    comment = strings(nFiles, 1);

    previousRows = normalizeRows(previousRows);
    for k = 1:nFiles
        match = find(previousRows.filePath == filePath(k), 1, "first");
        if isempty(match)
            continue;
        end
        label(k) = previousRows.label(match);
        comment(k) = previousRows.comment(match);
    end

    rows = table(recordingId(:), filePath(:), label(:), comment(:), ...
        'VariableNames', {'recordingId', 'filePath', 'label', 'comment'});
end

function files = discoverFiles(rootDirOrFiles)
    value = string(rootDirOrFiles);
    value = value(:);
    value = value(strlength(value) > 0);
    if isempty(value)
        error("rhs_preview:InvalidFolder", ...
            "RHS filtering requires at least one folder or RHS file.");
    end
    if isscalar(value) && exist(char(value), "dir") == 7
        files = string(labkit.rhs.findFiles(value));
        return;
    end
    isFile = arrayfun(@(pathValue) exist(char(pathValue), "file") == 2, value);
    if ~all(isFile)
        error("rhs_preview:InvalidFolder", ...
            "RHS filtering requires existing RHS files or one existing folder.");
    end
    [~, ~, ext] = arrayfun(@(pathValue) fileparts(char(pathValue)), value, ...
        'UniformOutput', false);
    if ~all(strcmpi(string(ext), ".rhs"))
        error("rhs_preview:InvalidFolder", ...
            "RHS filtering tasks must be .rhs files.");
    end
    files = value;
end

function rows = normalizeRows(rows)
    if ~istable(rows) || height(rows) == 0
        rows = table(strings(0, 1), strings(0, 1), strings(0, 1), ...
            strings(0, 1), ...
            'VariableNames', {'recordingId', 'filePath', 'label', 'comment'});
        return;
    end
    rows.recordingId = string(rows.recordingId);
    rows.filePath = string(rows.filePath);
    rows.label = string(rows.label);
    rows.comment = string(rows.comment);
end
