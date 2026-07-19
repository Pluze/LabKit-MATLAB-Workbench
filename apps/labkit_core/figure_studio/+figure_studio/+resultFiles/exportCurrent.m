function state = exportCurrent(state, context)
if isempty(state.session.cache.plotData), context.alert("No preview axes content is available to export.", "Figure Studio"); return; end
folder = state.project.parameters.outputFolder; if strlength(folder) == 0, chosen = context.chooseOutputFolder(pwd); if chosen.Cancelled, return; end; folder = string(chosen.Value); end
[fig, ax] = figure_studio.resultFiles.createStyledFigure(state.session.cache.plotData, state.project.parameters.style); cleanup = onCleanup(@() delete(fig));
payload = figure_studio.resultFiles.exportAxesPackage(ax, folder); state.project.results.lastExport = struct("kind", "package", "path", folder, "outputs", payload);
end
