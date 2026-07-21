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
    gold = figure_studio.styleLibrary.goldStandard();
    style = struct();
    style.name = string(name);
    style.fontName = preferredFont(name);
    style.baseFontSize = 20;
    style.titleFontOffset = 4;
    style.labelFontOffset = 4;
    style.tickFontOffset = 0;
    style.titleFontSize = gold.titleFontSize;
    style.labelFontSize = gold.labelFontSize;
    style.tickFontSize = gold.tickFontSize;
    style.annotationFontSize = gold.annotationFontSize;
    style.xTickLabelAngle = "Horizontal";
    style.fontOverrides = struct( ...
        'title', false, ...
        'label', false, ...
        'tick', false);
    style.dataLineWidth = gold.dataLineWidth;
    style.uncertaintyLineWidth = gold.uncertaintyLineWidth;
    style.boundaryLineWidth = gold.boundaryLineWidth;
    style.referenceLineWidth = gold.referenceLineWidth;
    style.axesLineWidth = gold.axesLineWidth;
    style.gridAlpha = 0.12;
    style.gridVisible = false;
    style.boxVisible = true;
    style.boundaryLines = true;
    style.legendVisible = "Source";
    style.legendLocation = "Source";
    style.legendFontSize = gold.legendFontSize;
    style.legendNumColumns = 0;
    style.legendBox = "On";
    style.canvasWidth = gold.canvasWidth;
    style.canvasHeight = gold.canvasHeight;
    style.referenceCanvasWidth = gold.canvasWidth;
    style.referenceCanvasHeight = gold.canvasHeight;
    style.axesPosition = gold.axesPosition;
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
