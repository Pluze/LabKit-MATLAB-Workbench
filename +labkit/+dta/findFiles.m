function filepaths = findFiles(rootDir)
%FINDFILES Find DTA files in a folder and its subfolders.
%
% Usage:
%   filepaths = labkit.dta.findFiles(rootDir)
%
% Description:
%   Recursively walks rootDir and collects files whose extension is .dta,
%   using a case-insensitive comparison. The function does not inspect file
%   contents; use detectType or loadFile to validate each result.
%
% Inputs:
%   rootDir - Character vector or string scalar naming an existing folder.
%
% Outputs:
%   filepaths - Cell row vector of full file paths in directory traversal
%       order. The value is an empty cell array when no DTA files are found.
%
% Errors:
%   Throws labkit:dta:InvalidFolder when rootDir is not a text scalar or does
%   not name an existing folder.
%
% Example:
%   files = labkit.dta.findFiles("data");
%   [items, report] = labkit.dta.loadFiles(files, "auto");

    rootDir = normalizeRootDir(rootDir);
    filepaths = findDTAFilesRecursive(rootDir);
end

function rootDir = normalizeRootDir(rootDir)
    if ~(ischar(rootDir) || (isstring(rootDir) && isscalar(rootDir)))
        error('labkit:dta:InvalidFolder', 'Root folder must be a character vector or scalar string.');
    end

    rootDir = char(rootDir);
    if exist(rootDir, 'dir') ~= 7
        error('labkit:dta:InvalidFolder', 'Root folder must be an existing folder.');
    end
end
