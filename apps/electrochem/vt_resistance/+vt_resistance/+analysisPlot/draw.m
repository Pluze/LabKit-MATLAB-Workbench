% Expected caller: VT Resistance plot area renderer. Inputs are
% one axes and a prepared app-owned model. Side effects are limited to
% replacing graphics on the supplied axes.
function draw(axesById, model)
drawOne(axesById.top, model.top);
drawOne(axesById.bottom, model.bottom);
end

function drawOne(ax, model)
    labkit.app.plot.clearAxes(ax, "ResetScale", true);
    if ~model.valid
        title(ax, model.title);
        if strlength(model.message) > 0
            text(ax, 0.5, 0.5, model.message, ...
                'Units', 'normalized', 'HorizontalAlignment', 'center');
        end
        return;
    end

    a = model.analysis;
    c = plotCoordinates(a, model.xChoice);
    choices = vt_resistance.analysisRun.analysisChoices();
    if model.yChoice == choices.yAxes(1)
        lineHandle = plot(ax, c.x, a.Vf, 'LineWidth', 1.25, ...
            'Color', [0 0.4470 0.7410]);
        yLabel = 'Vf (V vs Ref.)';
        plotTitle = sprintf('%s | VT | Ravg = %.6g ohm', ...
            model.itemName, a.Ravg_abs_ohm);
        isVoltage = true;
    else
        lineHandle = plot(ax, c.x, a.Im, 'LineWidth', 1.25, ...
            'Color', [0.8500 0.3250 0.0980]);
        yLabel = 'Im (A)';
        plotTitle = sprintf('%s | IT | Ic %.4g A, Ia %.4g A', ...
            model.itemName, a.Ic_est_A, a.Ia_est_A);
        isVoltage = false;
    end
    labkit.app.plot.fitAxesToGraphics(ax, lineHandle);
    hold(ax, 'on');
    if model.showShading
        addShading(ax, c);
    end
    if model.showMarkers
        addMarkers(ax, c);
        if isVoltage
            vt_resistance.analysisPlot.addResistanceVTAnnotations(ax, a, ...
                c.cathBaseStart, c.cathBaseEnd, ...
                c.anodBaseStart, c.anodBaseEnd, ...
                c.cathSteadyStart, c.cathSteadyEnd, ...
                c.anodSteadyStart, c.anodSteadyEnd, ...
                c.cathStart, c.cathEnd, c.anodStart, c.anodEnd);
        else
            vt_resistance.analysisPlot.addResistanceITAnnotations(ax, a, ...
                c.cathSteadyStart, c.cathSteadyEnd, ...
                c.anodSteadyStart, c.anodSteadyEnd, ...
                c.cathStart, c.cathEnd, c.anodStart, c.anodEnd);
        end
    end
    hold(ax, 'off');
    title(ax, plotTitle, 'Interpreter', 'none');
    xlabel(ax, c.xLabel);
    ylabel(ax, yLabel);
    setGrid(ax, model.showGrid);
end

function c = plotCoordinates(a, xChoice)
    choices = vt_resistance.analysisRun.analysisChoices();
    useSamples = string(xChoice) == choices.xAxes(2);
    c.x = a.t;
    c.xLabel = choices.xAxes(1);
    names = ["cathStart", "cathEnd", "anodStart", "anodEnd", ...
        "cathBaseStart", "cathBaseEnd", "anodBaseStart", "anodBaseEnd", ...
        "cathSteadyStart", "cathSteadyEnd", ...
        "anodSteadyStart", "anodSteadyEnd"];
    times = [a.pulse.cath.start_s, a.pulse.cath.end_s, ...
        a.pulse.anod.start_s, a.pulse.anod.end_s, ...
        a.pulse.pre.start_s, a.pulse.pre.end_s, ...
        a.anodBaselineStart, a.anodBaselineEnd, ...
        a.cathSteadyStart, a.cathSteadyEnd, ...
        a.anodSteadyStart, a.anodSteadyEnd];
    if useSamples
        c.x = a.pt;
        c.xLabel = choices.xAxes(2);
        for k = 1:numel(times)
            c.(names(k)) = vt_resistance.analysisRun.interp1Safe( ...
                a.t, a.pt, times(k));
        end
    else
        for k = 1:numel(times)
            c.(names(k)) = times(k);
        end
    end
end

function addShading(ax, c)
    vt_resistance.analysisPlot.shadeWindow(ax, c.cathStart, c.cathEnd, ...
        [0.90 0.95 1.00], 0.12);
    vt_resistance.analysisPlot.shadeWindow(ax, c.anodStart, c.anodEnd, ...
        [1.00 0.94 0.88], 0.12);
    vt_resistance.analysisPlot.shadeWindow(ax, ...
        c.cathSteadyStart, c.cathSteadyEnd, [0.65 0.82 1.00], 0.22);
    vt_resistance.analysisPlot.shadeWindow(ax, ...
        c.anodSteadyStart, c.anodSteadyEnd, [1.00 0.75 0.55], 0.22);
end

function addMarkers(ax, c)
    xline(ax, c.cathStart, ':', 'Cath start', 'Color', [0.2 0.4 0.8]);
    xline(ax, c.cathEnd, ':', 'Cath end', 'Color', [0.2 0.4 0.8]);
    xline(ax, c.anodStart, ':', 'Anod start', 'Color', [0.8 0.4 0.2]);
    xline(ax, c.anodEnd, ':', 'Anod end', 'Color', [0.8 0.4 0.2]);
end

function setGrid(ax, enabled)
    if enabled
        grid(ax, 'on');
    else
        grid(ax, 'off');
    end
end
