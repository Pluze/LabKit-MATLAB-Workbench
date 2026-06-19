function filepaths = findFiles(rootDir)
%FINDFILES Recursively collect Intan RHS files without GUI side effects.
%
% Inputs:
%   rootDir - existing folder path.
%
% Output:
%   filepaths - cell array of discovered *.rhs file paths, sorted for
%               deterministic app display and batch processing.

    rootDir = normalizeRootDir(rootDir);
    entries = dir(fullfile(rootDir, "**", "*.rhs"));
    filepaths = cell(numel(entries), 1);
    for k = 1:numel(entries)
        filepaths{k} = fullfile(entries(k).folder, entries(k).name);
    end
    filepaths = sort(filepaths);
end

function rootDir = normalizeRootDir(rootDir)
    if ~(ischar(rootDir) || (isstring(rootDir) && isscalar(rootDir)))
        error("labkit:rhs:InvalidFolder", ...
            "Root folder must be a character vector or scalar string.");
    end

    rootDir = char(rootDir);
    if exist(rootDir, "dir") ~= 7
        error("labkit:rhs:InvalidFolder", ...
            "Root folder must be an existing folder.");
    end
end
