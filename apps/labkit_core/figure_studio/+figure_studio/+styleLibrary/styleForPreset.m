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
    style.name = "LabKit figure";
    style.fontName = preferredFont(name);
    style.baseFontSize = 36;
    style.titleFontOffset = 0;
    style.labelFontOffset = 0;
    style.tickFontOffset = 0;
    style.titleFontSize = 36;
    style.labelFontSize = 36;
    style.tickFontSize = 36;
    style.fontOverrides = struct( ...
        'title', false, ...
        'label', false, ...
        'tick', false);
    style.dataLineWidth = 3;
    style.axesLineWidth = 3;
    style.gridAlpha = 0.12;
    style.gridVisible = false;
    style.boxVisible = true;
    style.boundaryLines = true;
    style.canvasWidth = 720;
    style.canvasHeight = 540;
    style.exportScale = 2;
    style.colorOrder = colorOrder;
end

function fontName = preferredFont(~)
    names = listfonts;
    preferred = ["Arial", "Liberation Sans", "DejaVu Sans"];
    fontName = "Arial";
    for k = 1:numel(preferred)
        if any(strcmpi(names, preferred(k)))
            fontName = preferred(k);
            return;
        end
    end
end
