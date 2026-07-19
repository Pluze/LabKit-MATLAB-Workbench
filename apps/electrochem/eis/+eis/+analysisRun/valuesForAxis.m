% Expected caller: eis.overlayPlot.plotOverlay, eis.resultFiles, and unit
% tests. Inputs are an EIS item struct and axis label. Output is the selected
% numeric vector. No side effects.

function values = valuesForAxis(item, axisName)
    items = eis.overlayPlot.axisItems();
    switch axisName
        case char(items(1))
            values = itemField(item, 'freq_Hz', 'Freq');
        case char(items(2))
            values = log10(itemField(item, 'freq_Hz', 'Freq'));
        case char(items(3))
            values = itemField(item, 'time_s', 'Time');
        case char(items(4))
            values = itemField(item, 'point', 'Pt');
        case char(items(5))
            values = itemField(item, 'Zreal_ohm', 'Zreal');
        case char(items(6))
            values = itemField(item, 'Zimag_ohm', 'Zimag');
        case char(items(7))
            values = itemField(item, 'negZimag_ohm', 'negZimag');
        case char(items(8))
            values = itemField(item, 'Zmod_ohm', 'Zmod');
        case char(items(9))
            values = itemField(item, 'Zphz_deg', 'Zphz');
        case char(items(10))
            values = itemField(item, 'Idc_A', 'Idc');
        case char(items(11))
            values = itemField(item, 'Vdc_V', 'Vdc');
        otherwise
            error('Unsupported axis selection: %s', axisName);
    end
end

function values = itemField(item, canonicalName, legacyName)
    if isfield(item, canonicalName) && ~isempty(item.(canonicalName))
        values = item.(canonicalName);
    elseif isfield(item, legacyName) && ~isempty(item.(legacyName))
        values = item.(legacyName);
    else
        values = [];
    end
end
