% Expected caller: rhs_screen.run and unit tests. Inputs are one screening
% session plus the editable recording-curation table data from the GUI.
% Output is the session with keep/reviewNote and derived ids/groups refreshed.
function [session, report] = applyRecordingsTableData(session, data)
%APPLYRECORDINGSTABLEDATA Apply GUI curation edits to a screening session.

    recordings = recordingsTable(session);
    if height(recordings) == 0 || isempty(data)
        report = reportFromRecordings(recordings, table());
        return;
    end

    nRows = min(height(recordings), size(data, 1));
    for r = 1:nRows
        tableId = string(data{r, 2});
        targetRow = r;
        match = find(recordings.recordingId == tableId, 1, "first");
        if ~isempty(match)
            targetRow = match;
        end
        recordings.keep(targetRow) = logical(data{r, 1});
        recordings.reviewNote(targetRow) = string(data{r, 9});
    end

    session.recordings = recordings;
    session.groups = groupRecordings(recordings);
    session.acceptedRecordingIds = recordings.recordingId(logical(recordings.keep));
    report = reportFromRecordings(recordings, session.groups);
end

function recordings = recordingsTable(session)
    if isstruct(session) && isfield(session, "recordings") && istable(session.recordings)
        recordings = session.recordings;
    elseif isstruct(session) && isfield(session, "recordings") && isstruct(session.recordings)
        recordings = struct2table(session.recordings);
    else
        recordings = table();
    end

    if height(recordings) == 0
        return;
    end
    recordings.recordingId = string(recordings.recordingId);
    recordings.qcFlag = string(recordings.qcFlag);
    if ~ismember("keep", recordings.Properties.VariableNames)
        recordings.keep = recordings.qcFlag == "accepted";
    end
    recordings.keep = logical(recordings.keep);
    if ~ismember("reviewNote", recordings.Properties.VariableNames)
        recordings.reviewNote = strings(height(recordings), 1);
    end
    recordings.reviewNote = string(recordings.reviewNote);
end

function groups = groupRecordings(recordings)
    if height(recordings) == 0
        groups = table(strings(0, 1), NaN(0, 1), zeros(0, 1), ...
            zeros(0, 1), zeros(0, 1), ...
            'VariableNames', {'channelSignature', 'sampleRateHz', ...
            'recordingCount', 'acceptedCount', 'reviewCount'});
        return;
    end

    keys = string(recordings.channelSignature) + "|" + string(recordings.sampleRateHz);
    uniqueKeys = unique(keys, "stable");
    nGroups = numel(uniqueKeys);
    channelSignature = strings(nGroups, 1);
    sampleRateHz = NaN(nGroups, 1);
    recordingCount = zeros(nGroups, 1);
    acceptedCount = zeros(nGroups, 1);
    reviewCount = zeros(nGroups, 1);

    for k = 1:nGroups
        mask = keys == uniqueKeys(k);
        first = find(mask, 1, "first");
        channelSignature(k) = string(recordings.channelSignature(first));
        sampleRateHz(k) = double(recordings.sampleRateHz(first));
        recordingCount(k) = sum(mask);
        acceptedCount(k) = sum(mask & logical(recordings.keep));
        reviewCount(k) = sum(mask & recordings.qcFlag == "needsReview");
    end

    groups = table(channelSignature, sampleRateHz, recordingCount, ...
        acceptedCount, reviewCount, ...
        'VariableNames', {'channelSignature', 'sampleRateHz', ...
        'recordingCount', 'acceptedCount', 'reviewCount'});
end

function report = reportFromRecordings(recordings, groups)
    report = struct( ...
        "fileCount", height(recordings), ...
        "acceptedCount", sum(logicalColumn(recordings, "keep")), ...
        "keptCount", sum(logicalColumn(recordings, "keep")), ...
        "needsReviewCount", sum(stringColumn(recordings, "qcFlag") == "needsReview"), ...
        "failedCount", sum(stringColumn(recordings, "qcFlag") == "failed"), ...
        "groupCount", height(groups));
end

function value = logicalColumn(T, name)
    if height(T) == 0 || ~ismember(name, T.Properties.VariableNames)
        value = false(height(T), 1);
    else
        value = logical(T.(name));
    end
end

function value = stringColumn(T, name)
    if height(T) == 0 || ~ismember(name, T.Properties.VariableNames)
        value = strings(height(T), 1);
    else
        value = string(T.(name));
    end
end
