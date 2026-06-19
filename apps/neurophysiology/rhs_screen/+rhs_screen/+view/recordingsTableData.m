% Expected caller: rhs_screen.run/buildSpec. Input is app state. Output is a
% display/edit cell table for recording curation.
function data = recordingsTableData(S)
%RECORDINGSTABLEDATA Build editable RHS recording curation rows.

    recordings = recordingsTable(S);
    if height(recordings) == 0
        data = cell(0, 9);
        return;
    end

    data = cell(height(recordings), 9);
    for r = 1:height(recordings)
        data{r, 1} = logical(recordings.keep(r));
        data{r, 2} = char(recordings.recordingId(r));
        data{r, 3} = char(recordings.fileName(r));
        data{r, 4} = char(recordings.qcFlag(r));
        data{r, 5} = displayNumber(recordings.durationSec(r));
        data{r, 6} = displayNumber(recordings.sampleRateHz(r));
        data{r, 7} = double(recordings.amplifierChannelCount(r));
        data{r, 8} = char(recordings.reason(r));
        data{r, 9} = char(recordings.reviewNote(r));
    end
end

function recordings = recordingsTable(S)
    recordings = table();
    if isstruct(S) && isfield(S, "session") && isstruct(S.session) && ...
            isfield(S.session, "recordings") && istable(S.session.recordings)
        recordings = S.session.recordings;
    end
    if height(recordings) == 0
        return;
    end
    if ~ismember("keep", recordings.Properties.VariableNames)
        recordings.keep = recordings.qcFlag == "accepted";
    end
    if ~ismember("reviewNote", recordings.Properties.VariableNames)
        recordings.reviewNote = strings(height(recordings), 1);
    end
end

function text = displayNumber(value)
    value = double(value);
    if isempty(value) || ~isfinite(value)
        text = "";
    else
        text = char(compose("%.6g", value));
    end
end
