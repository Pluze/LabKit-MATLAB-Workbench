function T = buildChronoOverlayExportTable(items)
%BUILDCHRONOOVERLAYEXPORTTABLE Build aligned VT/IT overlay export table.

    timeUnion = [];
    for i = 1:numel(items)
        timeUnion = [timeUnion; alignedTime(items(i))]; %#ok<AGROW>
    end
    timeUnion = unique(timeUnion);
    timeUnion = sort(timeUnion);

    T = table(timeUnion, 'VariableNames', {'TimeGapCenterAligned_s'});
    for i = 1:numel(items)
        safeName = gamrywb.util.sanitizeFieldName(items(i).name);
        vName = ['V_' safeName];
        iName = ['I_' safeName];

        tAligned = alignedTime(items(i));
        Vf = voltage(items(i));
        Im = current(items(i));
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

function t = alignedTime(item)
    if isfield(item, 'tAligned') && ~isempty(item.tAligned)
        t = item.tAligned(:);
    elseif isfield(item, 'tAligned_s') && ~isempty(item.tAligned_s)
        t = item.tAligned_s(:);
    else
        t = [];
    end
end

function v = voltage(item)
    if isfield(item, 'Vf') && ~isempty(item.Vf)
        v = item.Vf(:);
    elseif isfield(item, 'Vf_V') && ~isempty(item.Vf_V)
        v = item.Vf_V(:);
    else
        v = [];
    end
end

function i = current(item)
    if isfield(item, 'Im') && ~isempty(item.Im)
        i = item.Im(:);
    elseif isfield(item, 'Im_A') && ~isempty(item.Im_A)
        i = item.Im_A(:);
    else
        i = [];
    end
end
