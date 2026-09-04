% Expected caller: ECG export action. Inputs are a prepared waveform request
% and output path. Side effect is one PNG rendered from the same app model as
% the live preview, without reading runtime UI handles.
function writeWaveformPng(request, outputPath)
    figureHandle = figure("Visible", "off", "Color", "white");
    cleanup = onCleanup(@() close(figureHandle));
    ax = axes(figureHandle);
    ecg_print.analysisRun.drawPreview( ...
        ax, struct("axisId", "wave", "kind", "wave", ...
        "request", request, "analysis", table(), ...
        "smoothBeats", 1, "unit", ""));
    exportgraphics(ax, outputPath, "Resolution", 300);
end
