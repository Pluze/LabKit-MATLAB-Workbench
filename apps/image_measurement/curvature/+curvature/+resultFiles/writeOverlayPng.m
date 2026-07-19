% Expected caller: curvature export action. Inputs are a prepared preview
% model and output path. Side effect is one PNG rendered from the same model as
% the live preview, without reading runtime UI handles.
function writeOverlayPng(model, outputPath)
    figureHandle = figure("Visible", "off", "Color", "white");
    cleanup = onCleanup(@() close(figureHandle));
    ax = axes(figureHandle);
    curvature.curvePreview.presentationData.renderCurvaturePreview(ax, model);
    exportgraphics(ax, outputPath, "Resolution", 300);
end
