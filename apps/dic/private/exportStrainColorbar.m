% App-owned DIC helper extracted from labkit_DICPostprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function exportStrainColorbar(opts, outfile)
    fig = figure('Visible', 'off', 'Position', [100 100 420 720]);
    cleanup = onCleanup(@() close(fig));
    ax = axes(fig, 'Position', [0.18 0.08 0.24 0.86]);
    levels = linspace(opts.colorRange(1), opts.colorRange(2), size(opts.colormap, 1));
    imagesc(ax, 1, levels, levels(:));
    set(ax, 'XTick', [], 'YDir', 'normal');
    ylabel(ax, 'Strain level');
    colormap(ax, opts.colormap);
    clim(ax, opts.colorRange);
    cb = colorbar(ax, 'Location', 'eastoutside');
    cb.Label.String = 'Strain level';
    exportgraphics(fig, outfile, 'Resolution', opts.exportResolution);
end
