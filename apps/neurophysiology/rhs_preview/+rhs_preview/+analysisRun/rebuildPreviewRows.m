function session = rebuildPreviewRows(session, parameters, savedRows)
%REBUILDPREVIEWROWS Reconcile indexed channels, protocol, and durable drafts.
if nargin < 3 || ~istable(savedRows)
    savedRows = table();
end
rows = rhs_preview.analysisRun.channelRows( ...
    session.cache.info, parameters.family, ...
    parameters.maxPreviewChannels, session.cache.protocol);
if height(rows) > 0 && height(savedRows) > 0 && ...
        all(ismember(["channel", "preview", "role", "label"], ...
        string(savedRows.Properties.VariableNames)))
    savedChannels = string(savedRows.channel);
    for row = 1:height(rows)
        match = find(savedChannels == string(rows.channel(row)), 1);
        if isempty(match)
            continue;
        end
        rows.preview(row) = logical(savedRows.preview(match));
        rows.role(row) = string(savedRows.role(match));
        rows.label(row) = string(savedRows.label(match));
    end
end
session.cache.previewChannelRows = rows;
end
