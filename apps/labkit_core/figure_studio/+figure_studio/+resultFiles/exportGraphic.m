function state = exportGraphic(state, context, format)
if isempty(state.session.cache.plotData), context.alert("No preview axes content is available to export.", "Figure Studio"); return; end
chosen = context.chooseOutputFile(["*." + format, upper(format) + " file"], "figure." + format); if chosen.Cancelled, return; end
[fig, ax] = figure_studio.resultFiles.createStyledFigure(state.session.cache.plotData, state.project.parameters.style); cleanup = onCleanup(@() delete(fig));
path = string(chosen.Value); if format == "fig", savefig(fig, path); elseif format == "svg", exportgraphics(ax, path, ContentType="vector"); else, exportgraphics(ax, path); end
state.project.results.lastExport = struct("kind", format, "path", path);
end
