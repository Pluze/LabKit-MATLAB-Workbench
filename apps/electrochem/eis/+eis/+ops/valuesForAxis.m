% Expected caller: EIS app runner and unit tests. Inputs are an EIS item struct
% and axis label. Output is the selected numeric vector. No side effects.

function values = valuesForAxis(item, axisName)
    switch axisName
        case 'Freq (Hz)'
            values = itemField(item, 'freq_Hz', 'Freq');
        case 'log10(Freq)'
            values = log10(itemField(item, 'freq_Hz', 'Freq'));
        case 'Time (s)'
            values = itemField(item, 'time_s', 'Time');
        case 'Point #'
            values = itemField(item, 'point', 'Pt');
        case 'Zreal (ohm)'
            values = itemField(item, 'Zreal_ohm', 'Zreal');
        case 'Zimag (ohm)'
            values = itemField(item, 'Zimag_ohm', 'Zimag');
        case '-Zimag (ohm)'
            values = itemField(item, 'negZimag_ohm', 'negZimag');
        case 'Zmod (ohm)'
            values = itemField(item, 'Zmod_ohm', 'Zmod');
        case 'Zphz (deg)'
            values = itemField(item, 'Zphz_deg', 'Zphz');
        case 'Idc (A)'
            values = itemField(item, 'Idc_A', 'Idc');
        case 'Vdc (V)'
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
