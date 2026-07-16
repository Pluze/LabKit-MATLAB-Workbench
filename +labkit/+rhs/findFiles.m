function filepaths = findFiles(rootDir)
%FINDFILES Find Intan RHS files in a folder and its subfolders.
%
% Usage:
%   filepaths = labkit.rhs.findFiles(rootDir)
%
% Description:
%   Recursively collects files whose extension is .rhs and sorts their full
%   paths for reproducible batch order. The function does not inspect file
%   headers; use inspectFile when the contents must be validated.
%
% Inputs:
%   rootDir - Character vector or string scalar naming an existing folder.
%
% Outputs:
%   filepaths - Cell column vector of sorted full paths. The value is an empty
%       cell array when no RHS files are found.
%
% Errors:
%   Throws labkit:rhs:InvalidFolder when rootDir is not a text scalar or does
%   not name an existing folder.
%
% Typical Call:
%   files = labkit.rhs.findFiles("recordings");
%   [info, status] = labkit.rhs.inspectFile(files{1});

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
