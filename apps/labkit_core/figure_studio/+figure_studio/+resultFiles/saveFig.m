% App-owned implementation for figure_studio.resultFiles.saveFig within the figure_studio product workflow.
function state = saveFig(state, context)
state = figure_studio.resultFiles.exportGraphic(state, context, "fig");
end
