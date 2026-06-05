% App-owned DIC helper extracted from labkit_DICPostprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function exportOverlayFigure(overlayImage, componentName, colorRange, resolution, outfile)
    fig = figure('Visible', 'off');
    cleanup = onCleanup(@() close(fig));
    imshow(overlayImage);
    title(sprintf('Strain %s', componentName));
    colormap(jet);
    clim(colorRange);
    cb = colorbar;
    cb.Label.String = sprintf('Strain %s', componentName);
    exportgraphics(fig, outfile, 'Resolution', resolution);
end
