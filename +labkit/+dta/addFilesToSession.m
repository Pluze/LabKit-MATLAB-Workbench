function [session, report] = addFilesToSession(session, filepaths, expectedKind, callbacks, opts)
%ADDFILESTOSESSION Load DTA files into a session through the DTA facade.
%
% Usage:
%   [session, report] = labkit.dta.addFilesToSession(session, files, "chrono");
%   callbacks = struct('onAdded', @onAdded, 'onSkipped', @onSkipped, ...
%       'onFailed', @onFailed);
%
% Inputs:
%   session - labkit_session struct from makeSession.
%   filepaths - path, string array, or cell array of paths.
%   expectedKind - "auto" (default), "chrono", "eis", or "cvct".
%   callbacks - optional struct with onAdded(item), onSkipped(filepath),
%               and onFailed(filepath,message).
%   opts - optional struct forwarded to loadFile.
%
% Output:
%   session - updated session.
%   report - struct with added, skipped, failed, and count fields.

    if nargin < 3
        expectedKind = "auto";
    end
    if nargin < 4
        callbacks = struct();
    end
    if nargin < 5
        opts = struct();
    end

    expectedKind = labkit.dta.normalizeExpectedKind(expectedKind);
    loader = @(filepath) loadOne(filepath, expectedKind, opts);
    [session, report] = addItemsToSession(session, filepaths, loader, callbacks);
    report.nAdded = numel(report.added);
    report.nSkipped = numel(report.skipped);
    report.nFailed = numel(report.failed);
end

function item = loadOne(filepath, expectedKind, opts)
    [item, status] = labkit.dta.loadFile(filepath, expectedKind, opts);
    if ~status.ok
        error('labkit:dta:LoadFailed', '%s', char(status.message));
    end
end
