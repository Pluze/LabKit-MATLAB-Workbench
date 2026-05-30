function [items, report] = loadFolder(rootDir, expectedKind, opts)
%LOADFOLDER Recursively discover and load supported DTA files from a folder.

    if nargin < 2
        expectedKind = "auto";
    end
    if nargin < 3
        opts = struct();
    end

    expectedKind = gamrywb.dta.normalizeExpectedKind(expectedKind);
    filepaths = gamrywb.dta.findFiles(rootDir);
    [items, report] = gamrywb.dta.loadFiles(filepaths, expectedKind, opts);
    report.folder = char(rootDir);
    report.filepaths = filepaths;
    report.nDiscovered = numel(filepaths);
end
