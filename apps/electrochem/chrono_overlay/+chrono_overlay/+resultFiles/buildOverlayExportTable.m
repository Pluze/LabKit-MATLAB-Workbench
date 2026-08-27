% Expected callers: Chrono result export and direct tests. Inputs are
% aligned chrono item structs. Output is the stable overlay export table. No
% file side effects.

function T = buildOverlayExportTable(items)
    timeChunks = cell(numel(items), 1);
    for i = 1:numel(items)
        timeChunks{i} = chronoAlignedTime(items(i));
    end
    timeUnion = vertcat(timeChunks{:});
    timeUnion = unique(timeUnion);
    timeUnion = sort(timeUnion);

    T = table(timeUnion, 'VariableNames', {'TimeGapCenterAligned_s'});
    for i = 1:numel(items)
        safeName = sanitizeFieldName(items(i).name);
        vName = ['V_' safeName];
        iName = ['I_' safeName];

        tAligned = chronoAlignedTime(items(i));
        Vf = chronoVoltage(items(i));
        Im = chronoCurrent(items(i));
        if numel(tAligned) >= 2
            vData = interp1(tAligned, Vf, timeUnion, 'linear', NaN);
            iData = interp1(tAligned, Im, timeUnion, 'linear', NaN);
        else
            vData = NaN(size(timeUnion));
            iData = NaN(size(timeUnion));
        end

        T.(vName) = vData;
        T.(iName) = iData;
    end
end

function t = chronoAlignedTime(item)
    if ~isfield(item, 'tAligned_s') || isempty(item.tAligned_s)
        t = [];
    else
        t = item.tAligned_s(:);
    end
end

function v = chronoVoltage(item)
    if ~isfield(item, 'Vf_V') || isempty(item.Vf_V)
        v = [];
    else
        v = item.Vf_V(:);
    end
end

function i = chronoCurrent(item)
    if ~isfield(item, 'Im_A') || isempty(item.Im_A)
        i = [];
    else
        i = item.Im_A(:);
    end
end

function out = sanitizeFieldName(txt)
    out = matlab.lang.makeValidName(txt);
end
