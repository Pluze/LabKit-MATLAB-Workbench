function [items, report] = loadFolder(rootDir, expectedKind, opts)
%LOADFOLDER Read every DTA file below a folder.
%
% Usage:
%   [items, report] = labkit.dta.loadFolder(rootDir)
%   [items, report] = labkit.dta.loadFolder(rootDir, expectedKind)
%   [items, report] = labkit.dta.loadFolder(rootDir, expectedKind, opts)
%
% Description:
%   Recursively discovers .dta files with findFiles and passes the resulting
%   list to loadFiles. Unsupported or unreadable files are recorded in report
%   while readable items are retained.
%
% Inputs:
%   rootDir - Character vector or string scalar naming an existing folder.
%   expectedKind - "auto", "chrono", "eis", or "cvct", with the same
%       normalization as loadFile. Default: "auto".
%   opts - Optional scalar structure forwarded to loadFiles and loadFile.
%
% Options:
%   pulseMode - Pulse-detection mode used for discovered chrono files. See
%       detectPulses for the legal labels and normalization behavior.
%   pulseOptions - Scalar structure accepted by detectPulses. When both
%       pulseOptions and pulseMode are present, pulseOptions takes precedence.
%
% Outputs:
%   items - Cell row vector of successfully loaded item structures.
%   report - loadFiles report with three additional discovery fields.
%
% Output Fields:
%   folder - Requested root folder as a character vector.
%   filepaths - Cell array of discovered DTA paths in traversal order.
%   nDiscovered - Number of discovered paths. This equals nRequested.
%   loaded - Cell array of paths that loaded successfully.
%   failed - Structure array describing failed inputs.
%   statuses - One loadFile status per discovered input.
%   nRequested - Number of discovered paths sent to loadFiles.
%   nLoaded - Number of successful items.
%   nFailed - Number of failed inputs.
%
% Errors:
%   Throws labkit:dta:InvalidFolder for an invalid rootDir and
%   labkit:dta:InvalidKind for an unsupported expectedKind.
%
% Typical Call:
%   [items, report] = labkit.dta.loadFolder("experiment", "auto");
%   fprintf("Found %d DTA files; loaded %d.\n", ...
%       report.nDiscovered, report.nLoaded)
%
% See also labkit.dta.findFiles,
%   labkit.dta.loadFiles,
%   labkit.dta.loadFile

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
