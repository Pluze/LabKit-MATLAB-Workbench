% DIC Postprocess export helper. Expected caller: labkit_DICPostprocess_app.
% Inputs are overlay image, component label, color range, resolution, and
% output path. Side effect: writes a PNG through an offscreen figure.
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
