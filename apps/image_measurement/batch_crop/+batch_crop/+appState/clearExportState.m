% App-owned export-state helper. Expected caller: batch-crop runner callbacks
% that mutate inputs or options. Input and output are the runner state struct.
% The helper clears only the last successful export record and fingerprint.
function S = clearExportState(S)
%CLEAREXPORTSTATE Mark the current batch-crop export result dirty.

    S.lastExport = [];
    S.lastExportFingerprint = "";
end
