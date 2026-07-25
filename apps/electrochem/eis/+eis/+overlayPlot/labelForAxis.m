% Expected caller: EIS app runner. Input is an axis selection label. Output is
% the display label used by the app. No side effects.

function txt = labelForAxis(axisName, impedanceUnit)
    if nargin < 2
        units = eis.impedanceDisplay.catalog();
        impedanceUnit = units.choices(3);
    end
    items = eis.overlayPlot.axisItems();
    txt = string(axisName);
    if any(txt == items(5:8))
        txt = txt + " (" + string(impedanceUnit) + ")";
    end
end
