% Expected caller: rhs_preview.run and rhs_preview.ui.buildSpec. Input is
% the app state struct. Output is a 2-column cell table for a resultTable.
% No UI handles or app state are mutated.
function data = summaryTableData(S)
%SUMMARYTABLEDATA Build RHS preview summary rows.

    S = normalizeState(S);
    info = S.info;
    data = { ...
        'RHS file', displayFile(S.rhsFile); ...
        'Protocol', displayFile(S.protocolFile); ...
        'Status', char(S.statusMessage); ...
        'Sample rate', displayNumber(fieldValue(info, "sampleRateHz"), " Hz"); ...
        'Duration', displayNumber(fieldValue(info, "durationSec"), " s"); ...
        'Samples', displayInteger(fieldValue(info, "sampleCount")); ...
        'Blocks exact', displayLogical(fieldValue(info, "exactBlocks")); ...
        'Amplifier channels', displayInteger(channelCount(info, "amplifier")); ...
        'ADC channels', displayInteger(channelCount(info, "boardAdc")); ...
        'Digital inputs', displayInteger(channelCount(info, "boardDigIn")); ...
        'Preview family', char(S.family); ...
        'Last action', char(S.lastAction)};
end

function S = normalizeState(S)
    if ~isstruct(S)
        S = struct();
    end
    defaults = struct( ...
        "rhsFile", "", ...
        "protocolFile", "", ...
        "family", "amplifier", ...
        "info", [], ...
        "statusMessage", "No RHS file selected.", ...
        "lastAction", "Ready");
    names = fieldnames(defaults);
    for k = 1:numel(names)
        if ~isfield(S, names{k})
            S.(names{k}) = defaults.(names{k});
        end
    end
end

function value = fieldValue(S, name)
    value = NaN;
    if isstruct(S) && isfield(S, name)
        value = S.(name);
    end
end

function n = channelCount(info, family)
    n = NaN;
    if isstruct(info) && isfield(info, "channelFamilies") && ...
            isfield(info.channelFamilies, family)
        n = numel(info.channelFamilies.(family));
    end
end

function text = displayFile(filepath)
    filepath = string(filepath);
    if strlength(filepath) == 0
        text = 'none';
        return;
    end
    [~, name, ext] = fileparts(char(filepath));
    text = [name ext];
end

function text = displayNumber(value, unit)
    if isnumeric(value) && isscalar(value) && isfinite(value)
        text = sprintf("%.6g%s", double(value), unit);
    else
        text = 'n/a';
    end
end

function text = displayInteger(value)
    if isnumeric(value) && isscalar(value) && isfinite(value)
        text = sprintf("%d", round(double(value)));
    else
        text = 'n/a';
    end
end

function text = displayLogical(value)
    if islogical(value) && isscalar(value)
        if value
            text = 'yes';
        else
            text = 'no';
        end
    else
        text = 'n/a';
    end
end
