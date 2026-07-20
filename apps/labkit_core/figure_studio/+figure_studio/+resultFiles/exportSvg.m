% App-owned implementation for figure_studio.resultFiles.exportSvg within the figure_studio product workflow.
function state = exportSvg(state, context)
state = figure_studio.resultFiles.exportGraphic(state, context, "svg");
end
