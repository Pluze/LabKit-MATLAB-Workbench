% Expected caller: registered CIC Runtime V2 renderer. Inputs are one axes
% and a prepared app-owned axis model. Side effects are limited to replacing
% graphics on the supplied axes.
function renderCicAxis(ax, model)
    labkit.ui.plot.clear(ax, "ResetScale", true);
    if ~model.valid
        title(ax, model.title);
        if strlength(model.message) > 0
            text(ax, 0.5, 0.5, model.message, ...
                'Units', 'normalized', 'HorizontalAlignment', 'center');
        end
        return;
    end

    request = model.request;
    analysis = model.analysis;
    coords = request.coords;
    lineHandle = plot(ax, request.x, request.y, ...
        'LineWidth', 1.25, 'Color', request.baseColor);
    labkit.ui.plot.fit(ax, lineHandle);
    hold(ax, 'on');
    if model.showShading
        cic.userInterface.shadeWindow(ax, coords.cathStartX, ...
            coords.cathEndX, [0.85 0.93 1.00]);
        cic.userInterface.shadeWindow(ax, coords.anodStartX, ...
            coords.anodEndX, [1.00 0.92 0.85]);
    end
    if strcmp(request.kind, 'VT') && model.showLimits
        yline(ax, analysis.cathLimit, '--', ...
            sprintf('Cath limit = %.3f V', analysis.cathLimit), ...
            'Color', [0.85 0.2 0.2], ...
            'LabelHorizontalAlignment', 'left');
        yline(ax, analysis.anodLimit, '--', ...
            sprintf('Anod limit = %.3f V', analysis.anodLimit), ...
            'Color', [0.85 0.2 0.2], ...
            'LabelHorizontalAlignment', 'left');
    end
    if strcmp(request.kind, 'VT')
        cic.userInterface.addBaselineYLines(ax, analysis);
    end
    if model.showMarkers
        addWindowMarkers(ax, coords);
        addAnalysisAnnotations(ax, request, analysis, coords);
    end
    hold(ax, 'off');
    title(ax, request.title, 'Interpreter', 'none');
    xlabel(ax, request.xLabel);
    ylabel(ax, request.yLabel);
    setGrid(ax, model.showGrid);
end

function addWindowMarkers(ax, coords)
    xline(ax, coords.cathStartX, ':', 'Cath start', ...
        'Color', [0.2 0.4 0.8]);
    xline(ax, coords.cathEndX, ':', 'Cath end', ...
        'Color', [0.2 0.4 0.8]);
    xline(ax, coords.anodStartX, ':', 'Anod start', ...
        'Color', [0.8 0.4 0.2]);
    xline(ax, coords.anodEndX, ':', 'Anod end', ...
        'Color', [0.8 0.4 0.2]);
end

function addAnalysisAnnotations(ax, request, analysis, coords)
    if strcmp(request.kind, 'VT')
        cic.userInterface.addPaperStyleVTAnnotations(ax, analysis, ...
            request.xChoice, coords.cathStartX, coords.cathEndX, ...
            coords.anodStartX, coords.anodEndX, coords.emcX, coords.emaX);
    else
        cic.userInterface.addPaperStyleITAnnotations(ax, analysis, ...
            request.xChoice, coords.cathStartX, coords.cathEndX, ...
            coords.anodStartX, coords.anodEndX, coords.emcX, coords.emaX);
    end
end

function setGrid(ax, enabled)
    if enabled
        grid(ax, 'on');
    else
        grid(ax, 'off');
    end
end
