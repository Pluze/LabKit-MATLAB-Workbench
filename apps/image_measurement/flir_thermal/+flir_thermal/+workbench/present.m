function view=present(state)
item=state.session.cache.currentItem; view=labkit.app.view.Snapshot();
view=view.enabled("exportImages",~isempty(item));
view=view.tableData("readingTable",cell(0,2),Columns=["Reading" "Temperature"]);
view=view.renderPlot("thermalPreview",struct("item",item,"parameters",state.project.parameters));
if ~isempty(item)
    view=view.limits("temperatureRange",item.rangeControlBounds);
    view=view.value("temperatureRange",item.displayRange);
end
sizeValue=[];if ~isempty(item),sizeValue=size(item.temperatureC);end
view=view.pointSlots("temperaturePoint",nan(1,2),ImageSize=sizeValue,Enabled=~isempty(item));
view=view.rectangle("temperatureRegion",[0 0 0 0],ImageSize=sizeValue,Enabled=~isempty(item));
end
