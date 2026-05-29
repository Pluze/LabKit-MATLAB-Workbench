function filepaths = findFiles(rootDir)
%FINDFILES Recursively collect Gamry DTA files without GUI side effects.

    rootDir = normalizeRootDir(rootDir);
    filepaths = gamrywb.io.findDTAFilesRecursive(rootDir);
end

function rootDir = normalizeRootDir(rootDir)
    if ~(ischar(rootDir) || (isstring(rootDir) && isscalar(rootDir)))
        error('gamrywb:dta:InvalidFolder', 'Root folder must be a character vector or scalar string.');
    end

    rootDir = char(rootDir);
end
