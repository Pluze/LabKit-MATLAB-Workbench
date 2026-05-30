function [session, report] = addFilesToSession(session, filepaths, expectedKind, callbacks, opts)
%ADDFILESTOSESSION Load DTA files into a session through the DTA facade.

    if nargin < 3
        expectedKind = "auto";
    end
    if nargin < 4
        callbacks = struct();
    end
    if nargin < 5
        opts = struct();
    end

    expectedKind = gamrywb.dta.normalizeExpectedKind(expectedKind);
    loader = @(filepath) loadOne(filepath, expectedKind, opts);
    [session, report] = addItemsToSession(session, filepaths, loader, callbacks);
    report.nAdded = numel(report.added);
    report.nSkipped = numel(report.skipped);
    report.nFailed = numel(report.failed);
end

function item = loadOne(filepath, expectedKind, opts)
    [item, status] = gamrywb.dta.loadFile(filepath, expectedKind, opts);
    if ~status.ok
        error('gamrywb:dta:LoadFailed', '%s', char(status.message));
    end
end
