% Expected caller: rhs_screen.run or unit tests. Input is one folder plus
% optional protocol/options struct. Output is a lightweight RHS screening
% session and summary report. Side effects are limited to RHS header reads.
function [session, report] = screenFolder(rootDir, opts)
%SCREENFOLDER Index RHS files and assign folder-level QC flags.

    if nargin < 2 || isempty(opts)
        opts = struct();
    end

    rootDir = string(rootDir);
    if ~isscalar(rootDir) || strlength(rootDir) == 0 || ...
            exist(char(rootDir), "dir") ~= 7
        error("rhs_screen:InvalidFolder", ...
            "RHS screening requires one existing folder.");
    end

    minDurationSec = double(optionValue(opts, "minDurationSec", 0));
    requireExactBlocks = logical(optionValue(opts, "requireExactBlocks", true));
    protocol = optionValue(opts, "protocol", struct());

    files = string(labkit.rhs.findFiles(rootDir));
    nFiles = numel(files);

    recordingId = strings(nFiles, 1);
    fileName = strings(nFiles, 1);
    filePath = strings(nFiles, 1);
    sampleRateHz = NaN(nFiles, 1);
    durationSec = NaN(nFiles, 1);
    sampleCount = NaN(nFiles, 1);
    amplifierChannelCount = zeros(nFiles, 1);
    channelSignature = strings(nFiles, 1);
    exactBlocks = false(nFiles, 1);
    keep = false(nFiles, 1);
    status = strings(nFiles, 1);
    qcFlag = strings(nFiles, 1);
    reason = strings(nFiles, 1);
    reviewNote = strings(nFiles, 1);

    for k = 1:nFiles
        filePath(k) = files(k);
        recordingId(k) = "R" + compose("%03d", k);
        [~, base, ext] = fileparts(char(files(k)));
        fileName(k) = string([base ext]);

        [index, indexStatus] = labkit.rhs.indexFile(files(k));
        status(k) = string(indexStatus.message);
        if strlength(status(k)) == 0
            status(k) = "ok";
        end

        if ~indexStatus.ok
            qcFlag(k) = "failed";
            channelSignature(k) = "<unreadable>";
            reason(k) = status(k);
            continue;
        end

        sampleRateHz(k) = index.sampleRateHz;
        durationSec(k) = index.durationSec;
        sampleCount(k) = index.sampleCount;
        exactBlocks(k) = index.exactBlocks;

        channels = string({index.info.channelFamilies.amplifier.nativeName}).';
        amplifierChannelCount(k) = numel(channels);
        channelSignature(k) = makeChannelSignature(channels);

        [qcFlag(k), reason(k)] = classifyRecording(index, ...
            minDurationSec, requireExactBlocks);
        keep(k) = qcFlag(k) == "accepted";
    end

    recordings = table(recordingId(:), fileName(:), filePath(:), sampleRateHz(:), ...
        durationSec(:), sampleCount(:), amplifierChannelCount(:), ...
        channelSignature(:), exactBlocks(:), keep(:), qcFlag(:), reason(:), ...
        reviewNote(:), status(:), ...
        'VariableNames', {'recordingId', 'fileName', 'filePath', ...
        'sampleRateHz', 'durationSec', 'sampleCount', ...
        'amplifierChannelCount', 'channelSignature', 'exactBlocks', ...
        'keep', 'qcFlag', 'reason', 'reviewNote', 'status'});

    groups = groupRecordings(recordings);
    session = struct( ...
        "type", "rhsScreenSession", ...
        "version", 1, ...
        "rootFolder", rootDir, ...
        "protocolSnapshot", protocol, ...
        "options", struct( ...
            "minDurationSec", minDurationSec, ...
            "requireExactBlocks", requireExactBlocks), ...
        "recordings", recordings, ...
        "groups", groups, ...
        "acceptedRecordingIds", recordings.recordingId(recordings.keep));

    report = struct( ...
        "fileCount", nFiles, ...
        "acceptedCount", sum(recordings.keep), ...
        "keptCount", sum(recordings.keep), ...
        "needsReviewCount", sum(recordings.qcFlag == "needsReview"), ...
        "failedCount", sum(recordings.qcFlag == "failed"), ...
        "groupCount", height(groups));
end

function value = optionValue(opts, fieldName, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, fieldName)
        value = opts.(fieldName);
    end
end

function signature = makeChannelSignature(channels)
    channels = string(channels(:));
    if isempty(channels)
        signature = "<no amplifier channels>";
        return;
    end
    signature = strjoin(sort(channels), ",");
end

function [flag, reason] = classifyRecording(index, minDurationSec, requireExactBlocks)
    flag = "accepted";
    reason = "ok";

    if ~index.hasData
        flag = "needsReview";
        reason = "header only";
        return;
    end

    if requireExactBlocks && ~index.exactBlocks
        flag = "needsReview";
        reason = "trailing partial data block";
        return;
    end

    if isfinite(minDurationSec) && minDurationSec > 0 && ...
            index.durationSec < minDurationSec
        flag = "needsReview";
        reason = "shorter than minimum duration";
    end
end

function groups = groupRecordings(recordings)
    if height(recordings) == 0
        groups = table(strings(0, 1), NaN(0, 1), zeros(0, 1), ...
            zeros(0, 1), zeros(0, 1), ...
            'VariableNames', {'channelSignature', 'sampleRateHz', ...
            'recordingCount', 'acceptedCount', 'reviewCount'});
        return;
    end

    keys = recordings.channelSignature + "|" + string(recordings.sampleRateHz);
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
        channelSignature(k) = recordings.channelSignature(first);
        sampleRateHz(k) = recordings.sampleRateHz(first);
        recordingCount(k) = sum(mask);
        acceptedCount(k) = sum(mask & acceptedMask(recordings));
        reviewCount(k) = sum(mask & recordings.qcFlag == "needsReview");
    end

    groups = table(channelSignature, sampleRateHz, recordingCount, ...
        acceptedCount, reviewCount, ...
        'VariableNames', {'channelSignature', 'sampleRateHz', ...
        'recordingCount', 'acceptedCount', 'reviewCount'});
end

function mask = acceptedMask(recordings)
    if ismember("keep", recordings.Properties.VariableNames)
        mask = logical(recordings.keep);
    else
        mask = recordings.qcFlag == "accepted";
    end
end
