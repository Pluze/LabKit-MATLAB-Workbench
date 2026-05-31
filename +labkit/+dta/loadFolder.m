function [items, report] = loadFolder(rootDir, expectedKind, opts)
%LOADFOLDER Recursively discover and load supported DTA files from a folder.
%
% Usage:
%   [items, report] = labkit.dta.loadFolder(folder, "chrono");
%
% Inputs:
%   rootDir - folder path to search recursively for *.DTA/*.dta files.
%   expectedKind - "auto" (default), "chrono", "eis", or "cvct".
%   opts - optional struct forwarded to loadFiles/loadFile.
%
% Output:
%   items - cell array of loaded DTA item structs.
%   report - load report plus folder, filepaths, and nDiscovered fields.

    if nargin < 2
        expectedKind = "auto";
    end
    if nargin < 3
        opts = struct();
    end

    expectedKind = normalizeExpectedKind(expectedKind);
    filepaths = labkit.dta.findFiles(rootDir);
    [items, report] = labkit.dta.loadFiles(filepaths, expectedKind, opts);
    report.folder = char(rootDir);
    report.filepaths = filepaths;
    report.nDiscovered = numel(filepaths);
end
