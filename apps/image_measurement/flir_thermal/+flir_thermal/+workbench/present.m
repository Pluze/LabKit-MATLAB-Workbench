function view=present(state)
item=state.session.cache.currentItem; view=labkit.app.view.Snapshot();
view=view.enabled("exportImages",~isempty(item));
view=view.tableData("readingTable",cell(0,2),Columns=["Reading" "Temperature"]);
view=view.renderPlot("thermalPreview",struct("item",item,"parameters",state.project.parameters));
sizeValue=[];if ~isempty(item),sizeValue=size(item.values);end
view=view.pointSlots("temperaturePoint",zeros(0,2),ImageSize=sizeValue,Enabled=~isempty(item));
view=view.rectangle("temperatureRegion",[0 0 0 0],ImageSize=sizeValue,Enabled=~isempty(item));
end
