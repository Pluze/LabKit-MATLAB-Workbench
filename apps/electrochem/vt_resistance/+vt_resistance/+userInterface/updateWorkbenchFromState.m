% App-owned renderer for VT Resistance. Expected caller is labkit.ui.app.run
% after actions update state. Inputs are app state and UI registry. Side
% effects are limited to UI control, table, text, and axes updates.
function updateWorkbenchFromState(state, ui, ~)
    renderFileList(state, ui);
    renderBatchTable(state, ui);
    renderResultsSummary(state, ui);
    renderPlots(state, ui);
end

function renderFileList(state, ui)
    if isempty(state.items)
        labkit.ui.view.setListItems(ui, 'files', {});
        ui.controls.files.status.Value = 'No files loaded';
        return;
    end

    paths = string({state.items.filepath}).';
    labkit.ui.view.setValue(ui, 'files', paths);
    current = currentIndex(state);
    files = labkit.ui.view.getFiles(ui, 'files');
    labkit.ui.view.setFileSelection(ui, 'files', files(current));
    ui.controls.files.status.Value = sprintf('%d file(s) loaded', ...
        numel(state.items));
end

function renderBatchTable(state, ui)
    if isempty(state.items)
        ui.controls.results.table.Data = cell(0, 9);
        return;
    end
    ui.controls.results.table.Data = ...
        vt_resistance.userInterface.buildBatchTableData(state.items);
end

function renderResultsSummary(state, ui)
    setSummaryDefaults(ui);
    if isempty(state.items) || isempty(state.current) || ...
            state.current < 1 || state.current > numel(state.items)
        return;
    end
    item = state.items(state.current);
    ui.controls.controlMode.valueHandle.Value = chronoControlModeText(item);
    if isempty(item.analysis) || ~item.analysis.ok
        if ~isempty(item.analysis) && isfield(item.analysis, 'message')
            ui.controls.status.valueHandle.Value = item.analysis.message;
        else
            ui.controls.status.valueHandle.Value = 'No valid analysis';
        end
        return;
    end

    analysis = item.analysis;
    ui.controls.detect.valueHandle.Value = sprintf('%s | %s', ...
        analysis.detectMode, analysis.detectMsg);
    ui.controls.window.valueHandle.Value = sprintf('%s | %s', ...
        analysis.windowMode, analysis.voltageMode);
    ui.controls.cathIV.valueHandle.Value = sprintf( ...
        'I=%.6e A | Vss=%.6f V | dV=%.6f V', ...
        analysis.Ic_est_A, analysis.Vc_ss_V, analysis.dVc_V);
    ui.controls.anodIV.valueHandle.Value = sprintf( ...
        'I=%.6e A | Vss=%.6f V | dV=%.6f V', ...
        analysis.Ia_est_A, analysis.Va_ss_V, analysis.dVa_V);
    ui.controls.cathBase.valueHandle.Value = sprintf('%.6f V', ...
        analysis.Vc_baseline_V);
    ui.controls.anodBase.valueHandle.Value = sprintf('%.6f V', ...
        analysis.Va_baseline_V);
    ui.controls.cathBaseWindow.valueHandle.Value = ...
        vt_resistance.userInterface.formatDurationUs(analysis.cathBaselineWindow_s);
    ui.controls.anodBaseWindow.valueHandle.Value = ...
        vt_resistance.userInterface.formatDurationUs(analysis.anodBaselineWindow_s);
    ui.controls.cathR.valueHandle.Value = sprintf( ...
        '%.6g ohm (signed %.6g)', analysis.Rc_abs_ohm, analysis.Rc_ohm);
    ui.controls.anodR.valueHandle.Value = sprintf( ...
        '%.6g ohm (signed %.6g)', analysis.Ra_abs_ohm, analysis.Ra_ohm);
    ui.controls.averageR.valueHandle.Value = sprintf('%.6g ohm', ...
        analysis.Ravg_abs_ohm);
    ui.controls.status.valueHandle.Value = analysis.message;
end

function setSummaryDefaults(ui)
    ids = ["controlMode", "detect", "window", "cathIV", "anodIV", ...
        "cathBase", "anodBase", "cathBaseWindow", "anodBaseWindow", ...
        "cathR", "anodR", "averageR", "status"];
    for k = 1:numel(ids)
        ui.controls.(char(ids(k))).valueHandle.Value = '-';
    end
end

function out = chronoControlModeText(item)
    out = 'Unknown chrono control mode';
    if ~isfield(item, 'controlMode')
        return;
    end

    switch string(item.controlMode)
        case "current"
            out = 'Current-controlled chrono';
        case "voltage"
            out = 'Voltage-controlled chrono';
    end
end

function renderPlots(state, ui)
    axTop = ui.controls.plotAxes.axesById.top;
    axBottom = ui.controls.plotAxes.axesById.bottom;
    clearAxis(axTop);
    clearAxis(axBottom);
    if isempty(state.items) || isempty(state.current) || ...
            state.current < 1 || state.current > numel(state.items)
        title(axTop, 'Top Plot');
        title(axBottom, 'Bottom Plot');
        return;
    end

    item = state.items(state.current);
    if isempty(item.analysis) || ~item.analysis.ok
        title(axTop, 'Top Plot');
        title(axBottom, 'Bottom Plot');
        text(axTop, 0.5, 0.5, 'No valid analysis', ...
            'Units', 'normalized', 'HorizontalAlignment', 'center');
        return;
    end
    analysis = item.analysis;
    plotOneAxis(axTop, analysis, ui.controls.topX.valueHandle.Value, ...
        ui.controls.topY.valueHandle.Value, ...
        ui.controls.topGrid.valueHandle.Value, item.name, ui);
    plotOneAxis(axBottom, analysis, ui.controls.bottomX.valueHandle.Value, ...
        ui.controls.bottomY.valueHandle.Value, ...
        ui.controls.bottomGrid.valueHandle.Value, item.name, ui);
end

function plotOneAxis(ax, analysis, xChoice, yChoice, showGrid, itemName, ui)
    if strcmp(xChoice, 'Sample #')
        x = analysis.pt;
        xlab = 'Sample #';
        cathStartX = vt_resistance.analysisRun.interp1Safe( ...
            analysis.t, analysis.pt, analysis.pulse.cath_start);
        cathEndX = vt_resistance.analysisRun.interp1Safe( ...
            analysis.t, analysis.pt, analysis.pulse.cath_end);
        anodStartX = vt_resistance.analysisRun.interp1Safe( ...
            analysis.t, analysis.pt, analysis.pulse.anod_start);
        anodEndX = vt_resistance.analysisRun.interp1Safe( ...
            analysis.t, analysis.pt, analysis.pulse.anod_end);
        cathBaseStartX = vt_resistance.analysisRun.interp1Safe( ...
            analysis.t, analysis.pt, analysis.pulse.pre_start);
        cathBaseEndX = vt_resistance.analysisRun.interp1Safe( ...
            analysis.t, analysis.pt, analysis.pulse.pre_end);
        anodBaseStartX = vt_resistance.analysisRun.interp1Safe( ...
            analysis.t, analysis.pt, analysis.anodBaselineStart);
        anodBaseEndX = vt_resistance.analysisRun.interp1Safe( ...
            analysis.t, analysis.pt, analysis.anodBaselineEnd);
        cSteadyStartX = vt_resistance.analysisRun.interp1Safe( ...
            analysis.t, analysis.pt, analysis.cathSteadyStart);
        cSteadyEndX = vt_resistance.analysisRun.interp1Safe( ...
            analysis.t, analysis.pt, analysis.cathSteadyEnd);
        aSteadyStartX = vt_resistance.analysisRun.interp1Safe( ...
            analysis.t, analysis.pt, analysis.anodSteadyStart);
        aSteadyEndX = vt_resistance.analysisRun.interp1Safe( ...
            analysis.t, analysis.pt, analysis.anodSteadyEnd);
    else
        x = analysis.t;
        xlab = 'Time (s)';
        cathStartX = analysis.pulse.cath_start;
        cathEndX = analysis.pulse.cath_end;
        anodStartX = analysis.pulse.anod_start;
        anodEndX = analysis.pulse.anod_end;
        cathBaseStartX = analysis.pulse.pre_start;
        cathBaseEndX = analysis.pulse.pre_end;
        anodBaseStartX = analysis.anodBaselineStart;
        anodBaseEndX = analysis.anodBaselineEnd;
        cSteadyStartX = analysis.cathSteadyStart;
        cSteadyEndX = analysis.cathSteadyEnd;
        aSteadyStartX = analysis.anodSteadyStart;
        aSteadyEndX = analysis.anodSteadyEnd;
    end

    if startsWith(yChoice, 'VT')
        plot(ax, x, analysis.Vf, 'LineWidth', 1.25, ...
            'Color', [0 0.4470 0.7410]);
        ylab = 'Vf (V vs Ref.)';
        ttl = sprintf('%s | VT | Ravg = %.6g ohm', ...
            itemName, analysis.Ravg_abs_ohm);
        hold(ax, 'on');
    else
        plot(ax, x, analysis.Im, 'LineWidth', 1.25, ...
            'Color', [0.8500 0.3250 0.0980]);
        ylab = 'Im (A)';
        ttl = sprintf('%s | IT | Ic %.4g A, Ia %.4g A', ...
            itemName, analysis.Ic_est_A, analysis.Ia_est_A);
        hold(ax, 'on');
    end

    if ui.controls.showShading.valueHandle.Value
        vt_resistance.userInterface.shadeWindow(ax, cathStartX, cathEndX, ...
            [0.90 0.95 1.00], 0.12);
        vt_resistance.userInterface.shadeWindow(ax, anodStartX, anodEndX, ...
            [1.00 0.94 0.88], 0.12);
        vt_resistance.userInterface.shadeWindow(ax, cSteadyStartX, cSteadyEndX, ...
            [0.65 0.82 1.00], 0.22);
        vt_resistance.userInterface.shadeWindow(ax, aSteadyStartX, aSteadyEndX, ...
            [1.00 0.75 0.55], 0.22);
    end
    if ui.controls.showMarkers.valueHandle.Value
        xline(ax, cathStartX, ':', 'Cath start', 'Color', [0.2 0.4 0.8]);
        xline(ax, cathEndX, ':', 'Cath end', 'Color', [0.2 0.4 0.8]);
        xline(ax, anodStartX, ':', 'Anod start', 'Color', [0.8 0.4 0.2]);
        xline(ax, anodEndX, ':', 'Anod end', 'Color', [0.8 0.4 0.2]);
        if startsWith(yChoice, 'VT')
            vt_resistance.userInterface.addResistanceVTAnnotations(ax, analysis, ...
                cathBaseStartX, cathBaseEndX, anodBaseStartX, anodBaseEndX, ...
                cSteadyStartX, cSteadyEndX, aSteadyStartX, aSteadyEndX, ...
                cathStartX, cathEndX, anodStartX, anodEndX);
        else
            vt_resistance.userInterface.addResistanceITAnnotations(ax, analysis, ...
                cSteadyStartX, cSteadyEndX, aSteadyStartX, aSteadyEndX, ...
                cathStartX, cathEndX, anodStartX, anodEndX);
        end
    end
    hold(ax, 'off');

    title(ax, ttl, 'Interpreter', 'none');
    xlabel(ax, xlab);
    ylabel(ax, ylab);
    if showGrid
        grid(ax, 'on');
    else
        grid(ax, 'off');
    end
end

function idx = currentIndex(state)
    idx = state.current;
    if isempty(idx) || idx < 1 || idx > numel(state.items)
        idx = 1;
    end
end

function clearAxis(ax)
    vt_resistance.userInterface.clearPlotAxis(ax);
end
