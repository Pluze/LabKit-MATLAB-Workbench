% Expected caller: chrono_overlay.stateHandlers and export tests. Inputs are
% aligned chrono item structs. Output is the stable overlay export table. No
% file side effects.

function T = buildOverlayExportTable(items)
    timeUnion = [];
    for i = 1:numel(items)
        timeUnion = [timeUnion; chronoAlignedTime(items(i))];
    end
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
    if isfield(item, 'tAligned_s') && ~isempty(item.tAligned_s)
        t = item.tAligned_s(:);
    elseif isfield(item, 'tAligned') && ~isempty(item.tAligned)
        t = item.tAligned(:);
    else
        t = [];
    end
end

function v = chronoVoltage(item)
    if isfield(item, 'Vf_V') && ~isempty(item.Vf_V)
        v = item.Vf_V(:);
    elseif isfield(item, 'Vf') && ~isempty(item.Vf)
        v = item.Vf(:);
    else
        v = [];
    end
end

function i = chronoCurrent(item)
    if isfield(item, 'Im_A') && ~isempty(item.Im_A)
        i = item.Im_A(:);
    elseif isfield(item, 'Im') && ~isempty(item.Im)
        i = item.Im(:);
    else
        i = [];
    end
end

function out = sanitizeFieldName(txt)
    out = matlab.lang.makeValidName(txt);
end
