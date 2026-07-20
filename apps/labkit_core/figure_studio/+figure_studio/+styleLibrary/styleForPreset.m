% Expected caller: Figure Studio actions and initial state. Input is the style
% mode label. Output is the LabKit single-panel figure style parameter struct
% suitable for figure_studio.resultFiles.applyFigureStyle. Side effects are
% none.
function style = styleForPreset(name)
    if nargin < 1
        name = "LabKit figure";
    end
    style = baseStyle(string(name), [ ...
        0.00 0.00 0.00
        0.90 0.10 0.10
        0.00 0.38 0.90
        0.08 0.62 0.28
        0.55 0.28 0.80
        0.45 0.45 0.45]);
end

function style = baseStyle(name, colorOrder)
    style = struct();
    style.name = string(name);
    style.fontName = preferredFont(name);
    style.baseFontSize = 20;
    style.titleFontOffset = 4;
    style.labelFontOffset = 4;
    style.tickFontOffset = 0;
    style.titleFontSize = 24;
    style.labelFontSize = 24;
    style.tickFontSize = 20;
    style.annotationFontSize = 20;
    style.xTickLabelAngle = "Horizontal";
    style.fontOverrides = struct( ...
        'title', false, ...
        'label', false, ...
        'tick', false);
    style.dataLineWidth = 1.2;
    style.uncertaintyLineWidth = 1.1;
    style.boundaryLineWidth = 1.1;
    style.referenceLineWidth = 1.2;
    style.axesLineWidth = 1.2;
    style.gridAlpha = 0.12;
    style.gridVisible = false;
    style.boxVisible = true;
    style.boundaryLines = true;
    style.legendVisible = "Source";
    style.legendLocation = "Source";
    style.legendFontSize = 15;
    style.legendNumColumns = 0;
    style.legendBox = "On";
    style.canvasWidth = 720;
    style.canvasHeight = 600;
    style.referenceCanvasWidth = 720;
    style.referenceCanvasHeight = 600;
    style.exportScale = 2;
    style.colorOrder = colorOrder;
end

function fontName = preferredFont(~)
    names = listfonts;
    preferred = ["Helvetica", "Arial", "Liberation Sans", "DejaVu Sans"];
    fontName = "Arial";
    for k = 1:numel(preferred)
        if any(strcmpi(names, preferred(k)))
            fontName = preferred(k);
            return;
        end
    end
end
