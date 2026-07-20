% App-owned implementation for figure_studio.resultFiles.exportPng within the figure_studio product workflow.
function state = exportPng(state, context)
state = figure_studio.resultFiles.exportGraphic(state, context, "png");
end
