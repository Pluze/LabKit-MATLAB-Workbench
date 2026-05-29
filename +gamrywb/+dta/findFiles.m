function filepaths = findFiles(rootDir)
%FINDFILES Recursively collect Gamry DTA files without GUI side effects.

    filepaths = gamrywb.io.findDTAFilesRecursive(rootDir);
end
