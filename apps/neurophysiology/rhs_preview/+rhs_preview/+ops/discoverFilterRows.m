% Expected caller: rhs_preview.run and unit tests. Inputs are one root folder
% plus optional previous filter rows. Output is the recursive RHS file list
% with user labels/comments preserved by file path. No QC is performed.
function rows = discoverFilterRows(rootDir, previousRows)
%DISCOVERFILTERROWS Build editable RHS file filter rows.

    if nargin < 2 || isempty(previousRows)
        previousRows = table();
    end

    rootDir = string(rootDir);
    if ~isscalar(rootDir) || strlength(rootDir) == 0 || ...
            exist(char(rootDir), "dir") ~= 7
        error("rhs_preview:InvalidFolder", ...
            "RHS filtering requires one existing folder.");
    end

    files = string(labkit.rhs.findFiles(rootDir));
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
