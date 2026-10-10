% Expected caller: ECG export action. Inputs are a prepared waveform request
% and output path. Side effect is one PNG rendered from the same app model as
% the live preview, without reading runtime UI handles.
function writeWaveformPng(request, outputPath)
    figureHandle = figure("Visible", "off", "Color", "white");
    cleanup = onCleanup(@() close(figureHandle));
    ax = axes(figureHandle);
    plot(ax,request.x,request.y,'Color',request.lineColor);
    hold(ax,'on');scatter(ax,request.peakX,request.peakY,12,request.peakColor,'filled');
    title(ax,request.title,'Interpreter','none');xlabel(ax,request.xLabel);
    ylabel(ax,request.yLabel);grid(ax,'on');
    exportgraphics(ax, outputPath, "Resolution", 300);
end
