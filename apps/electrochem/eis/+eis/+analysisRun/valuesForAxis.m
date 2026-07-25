% Expected caller: eis.overlayPlot.plotOverlay, eis.resultFiles, and unit
% tests. Inputs are an EIS item struct and axis label. Output is the selected
% numeric vector. No side effects.

function values = valuesForAxis(item, axisName)
    items = eis.overlayPlot.axisItems();
    switch axisName
        case char(items(1))
            values = item.freq_Hz;
        case char(items(2))
            values = log10(item.freq_Hz);
        case char(items(3))
            values = item.time_s;
        case char(items(4))
            values = item.point;
        case char(items(5))
            values = item.Zreal_ohm;
        case char(items(6))
            values = item.Zimag_ohm;
        case char(items(7))
            values = item.negZimag_ohm;
        case char(items(8))
            values = item.Zmod_ohm;
        case char(items(9))
            values = item.Zphz_deg;
        case char(items(10))
            values = item.Idc_A;
        case char(items(11))
            values = item.Vdc_V;
        otherwise
            error('Unsupported axis selection: %s', axisName);
    end
end
