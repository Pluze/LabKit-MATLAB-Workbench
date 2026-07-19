function view=present(state)
cache=state.session.cache; view=labkit.app.view.Snapshot();
view=view.enabled("applyTool",~isempty(cache.item)); view=view.enabled("undoHistory",~isempty(state.project.annotations.sharedSteps)); view=view.enabled("resetHistory",~isempty(state.project.annotations.sharedSteps));
view=view.tableData("resultTable",{"Images",numel(state.project.inputs.sources);"Steps",numel(state.project.annotations.sharedSteps)},Columns=["Metric" "Value"]);
view=view.text("details","Select images and apply enhancement steps.");
view=view.renderPlot("preview",struct("source",cache.previewSource,"result",cache.previewResult));
sizeValue=[];if ~isempty(cache.previewSource),sizeValue=size(cache.previewSource);end
view=view.rectangle("whiteRoi",[0 0 0 0],ImageSize=sizeValue,Enabled=~isempty(cache.previewSource));
end
