% Expected caller: registered CSC Runtime V2 renderer. Inputs are one axes
% and a prepared axis model. Side effects are limited to supplied graphics.
function draw(axesById, model)
renderCscAxis(axesById.top, model.top);
renderCscAxis(axesById.bottom, model.bottom);
end

function renderCscAxis(ax, model)
    if ~model.valid
        labkit.app.plot.clearAxes(ax, ResetScale=true);
        title(ax, model.title);
        xlabel(ax, 'X');
        ylabel(ax, 'Y');
        return;
    end
    if model.curveIndex == 0
        opts = struct( ...
            "showGrid", model.showGrid, ...
            "title", model.title + " (all cycles)", ...
            "curveIndices", model.curveIndices);
        csc.analysisPlot.plotAllCycles(ax, model.curves, ...
            model.xSelection, model.ySelection, opts);
        return;
    end

    curve = model.curves(model.curveIndex);
    request = csc.analysisPlot.plotRequest(curve, ...
        model.xSelection, model.ySelection, upperFirst(model.axisId));
    opts = struct( ...
        "holdPlot", model.holdPlot, ...
        "showGrid", model.showGrid, ...
        "lineWidth", 1.2);
    info = csc.analysisPlot.plotXY( ...
        ax, request.x, request.y, request.labels, opts);
    clearTrim(ax);
    if info.ok && model.showTrim && model.ySelection == "Im" && ...
            isstruct(model.analysis) && isfield(model.analysis, 'ok') && ...
            model.analysis.ok
        drawTrimOverlay(ax, curve, model.xSelection, ...
            model.ySelection, model.analysis);
    end
end

function drawTrimOverlay(ax, curve, xSelection, ySelection, result)
    [xValues, ~, ~, ~] = labkit.dta.getCurveXY( ...
        curve, xSelection, ySelection);
    overlay = csc.analysisPlot.trimOverlayData( ...
        true, ySelection, xValues, result);
    if ~overlay.ok
        return;
    end
    hold(ax, 'on');
    plot(ax, overlay.x, overlay.cathY, ...
        'Color', [0.1 0.6 0.1], 'LineWidth', 1.0, 'Tag', 'trimCath');
    plot(ax, overlay.x, overlay.anodY, ...
        'Color', [0.8 0.3 0.1], 'LineWidth', 1.0, 'Tag', 'trimAnod');
    hold(ax, 'off');
end

function clearTrim(ax)
    delete(findobj(ax, 'Tag', 'trimCath'));
    delete(findobj(ax, 'Tag', 'trimAnod'));
end

function text = upperFirst(value)
    text = char(value);
    text(1) = upper(text(1));
end
