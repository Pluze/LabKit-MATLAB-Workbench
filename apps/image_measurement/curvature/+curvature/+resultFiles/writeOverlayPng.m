% App-owned implementation for curvature.resultFiles.writeOverlayPng within the curvature product workflow.
function writeOverlayPng(model, outputPath)
%WRITEOVERLAYPNG Render the live Curvature overlay model to one PNG.
figureHandle = figure("Visible", "off", "Color", "white");
cleanup = onCleanup(@() close(figureHandle));
ax = axes(figureHandle);
curvature.curvePreview.draw(struct("image", ax), model);
exportgraphics(ax, outputPath, "Resolution", 300);
end
