function values = valuesForEISAxis(item, axisName)
%VALUESFOREISAXIS Return legacy EIS values for a selected axis label.

    switch axisName
        case 'Freq (Hz)'
            values = item.Freq;
        case 'log10(Freq)'
            values = log10(item.Freq);
        case 'Time (s)'
            values = item.Time;
        case 'Point #'
            values = item.Pt;
        case 'Zreal (ohm)'
            values = item.Zreal;
        case 'Zimag (ohm)'
            values = item.Zimag;
        case '-Zimag (ohm)'
            values = item.negZimag;
        case 'Zmod (ohm)'
            values = item.Zmod;
        case 'Zphz (deg)'
            values = item.Zphz;
        case 'Idc (A)'
            values = item.Idc;
        case 'Vdc (V)'
            values = item.Vdc;
        otherwise
            error('Unsupported axis selection: %s', axisName);
    end
end
