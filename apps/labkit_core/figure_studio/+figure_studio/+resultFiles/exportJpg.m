% App-owned implementation for figure_studio.resultFiles.exportJpg within the figure_studio product workflow.
function state = exportJpg(state, context)
state = figure_studio.resultFiles.exportGraphic(state, context, "jpg");
end
