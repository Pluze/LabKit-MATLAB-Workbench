% App-owned renderer for ECG Print. Expected caller is labkit.ui.runtime.run
% after actions update state. Inputs are app state and UI registry. Side
% effects are limited to UI controls, tables, text, and preview axes.
function updateWorkbenchFromState(state, ui, ~)
    renderImportState(state, ui);
    renderSummary(state, ui);
    renderPlots(state, ui);
end

function renderImportState(state, ui)
    ui.controls.recording.status.Value = char(state.fileStatus);
    ui.controls.importStatus.valueHandle.Value = char(state.importStatus);
    ui.controls.filePreview.textArea.Value = state.filePreview;
    ddChannel = ui.controls.channel.valueHandle;
    ddChannel.Items = state.channelItems;
    if any(strcmp(ddChannel.Items, state.selectedChannel))
        ddChannel.Value = char(state.selectedChannel);
    elseif ~isempty(ddChannel.Items)
        ddChannel.Value = ddChannel.Items{1};
    end
end

function renderSummary(state, ui)
    ui.controls.summaryTable.table.Data = ecg_print.userInterface.summaryRows( ...
        state.signal, state.events, state.segments, state.measurements);
end

function renderPlots(state, ui)
    resetAxes(ui);
    if isempty(state.workingSignal)
        return;
    end

    request = ecg_print.userInterface.waveformPlotRequest(state.workingSignal, ...
        state.filteredSignal, state.events);
    ax = ui.controls.previewAxes.axesById.wave;
    plot(ax, request.x, request.y, 'Color', request.lineColor, ...
        'LineWidth', 1);
    hold(ax, 'on');
    if ~isempty(request.peakX)
        scatter(ax, request.peakX, request.peakY, 24, ...
            request.peakColor, 'filled');
    end
    hold(ax, 'off');
    title(ax, request.title);
    xlabel(ax, request.xLabel);
    ylabel(ax, request.yLabel);
    grid(ax, 'on');

    if isempty(state.measurements)
        return;
    end

    smoothBeats = max(1, round(ui.controls.smoothBeats.valueHandle.Value));
    T = ecg_print.resultFiles.analysisTable(state.measurements.perSegment, ...
        smoothBeats);

    noiseAx = ui.controls.previewAxes.axesById.noise;
    plot(noiseAx, T.EventTime, T.NoiseRMS, '.', 'MarkerSize', 12, ...
        'Color', [0.20 0.45 0.72]);
    hold(noiseAx, 'on');
    plot(noiseAx, T.EventTime, T.NoiseRMS_smooth, '-', ...
        'LineWidth', 1.5, 'Color', [0.05 0.20 0.45]);
    hold(noiseAx, 'off');
    title(noiseAx, sprintf( ...
        'Template Noise RMS Over Time | Smooth=%d beats', smoothBeats));
    xlabel(noiseAx, 'Time (s)');
    ylabel(noiseAx, 'Noise RMS');
    grid(noiseAx, 'on');

    snrAx = ui.controls.previewAxes.axesById.snr;
    plot(snrAx, T.EventTime, T.SNRdB, '.', 'MarkerSize', 12, ...
        'Color', [0.18 0.55 0.32]);
    hold(snrAx, 'on');
    plot(snrAx, T.EventTime, T.SNRdB_smooth, '-', ...
        'LineWidth', 1.5, 'Color', [0.05 0.32 0.16]);
    hold(snrAx, 'off');
    title(snrAx, sprintf('Template SNR Over Time | Smooth=%d beats', ...
        smoothBeats));
    xlabel(snrAx, 'Time (s)');
    ylabel(snrAx, 'SNR (dB)');
    grid(snrAx, 'on');

    renderTemplatePlot(state, ui);
end

function renderTemplatePlot(state, ui)
    ax = ui.controls.previewAxes.axesById.template;
    labkit.ui.plot.reset(ui, 'previewAxes', ...
        'Template + Residual Band', true, 'template');
    xlabel(ax, 'Time from peak (s)');
    ylabel(ax, 'Amplitude');
    request = ecg_print.userInterface.templatePlotRequest(state.segments, ...
        state.template, state.measurements, ...
        ui.controls.templateView.valueHandle.Value);
    if ~request.ok
        return;
    end

    hold(ax, 'on');
    if request.showSegments
        plot(ax, request.timeOffset, ...
            request.segments(:, request.showIndex), ...
            'Color', [0.78 0.84 0.92], 'LineWidth', 0.5);
    else
        fill(ax, [request.timeOffset; flipud(request.timeOffset)], ...
            [request.upper; flipud(request.lower)], [0.20 0.20 0.20], ...
            'FaceAlpha', 0.15, 'EdgeColor', 'none');
    end
    title(ax, request.title);
    plot(ax, request.timeOffset, request.template, 'k-', 'LineWidth', 2);
    xline(ax, 0, '--r', 'R');
    if ~isempty(request.signalWindowSec)
        shadeMeasurementWindows(ax, request);
    end
    hold(ax, 'off');
    grid(ax, 'on');
end

function shadeMeasurementWindows(ax, request)
    yl = ax.YLim;
    windowHandles = gobjects(0);
    windowHandles(end + 1) = drawWindow(ax, request.signalWindowSec, ...
        yl, [1.00 0.20 0.20], 0.08);
    noiseWindows = request.noiseWindowsSec;
    for k = 1:size(noiseWindows, 1)
        windowHandles(end + 1) = drawWindow(ax, noiseWindows(k, :), ...
            yl, [0.00 0.45 1.00], 0.08);
    end
    try
        uistack(windowHandles, 'bottom');
    catch
    end
end

function h = drawWindow(ax, windowSec, yl, color, alpha)
    h = fill(ax, [windowSec(1) windowSec(2) windowSec(2) windowSec(1)], ...
        [yl(1) yl(1) yl(2) yl(2)], color, ...
        'FaceAlpha', alpha, 'EdgeColor', 'none', ...
        'HitTest', 'off', 'PickableParts', 'none');
end

function resetAxes(ui)
    labkit.ui.plot.reset(ui, 'previewAxes', ...
        'Waveform + Peaks', true, 'wave');
    xlabel(ui.controls.previewAxes.axesById.wave, 'Time (s)');
    ylabel(ui.controls.previewAxes.axesById.wave, 'Amplitude');
    labkit.ui.plot.reset(ui, 'previewAxes', ...
        'Template Noise RMS Over Time', true, 'noise');
    xlabel(ui.controls.previewAxes.axesById.noise, 'Time (s)');
    ylabel(ui.controls.previewAxes.axesById.noise, 'Noise RMS');
    labkit.ui.plot.reset(ui, 'previewAxes', ...
        'Template SNR Over Time', true, 'snr');
    xlabel(ui.controls.previewAxes.axesById.snr, 'Time (s)');
    ylabel(ui.controls.previewAxes.axesById.snr, 'SNR (dB)');
    labkit.ui.plot.reset(ui, 'previewAxes', ...
        'Template + Residual Band', true, 'template');
    xlabel(ui.controls.previewAxes.axesById.template, 'Time from peak (s)');
    ylabel(ui.controls.previewAxes.axesById.template, 'Amplitude');
end
