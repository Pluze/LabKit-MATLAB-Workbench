function state=exportImages(state,context)
if isempty(state.project.inputs.sources),context.alert("Load FLIR images before export.","No images");return,end
choice=context.chooseOutputFolder(state.project.parameters.outputFolder);if choice.Cancelled,return,end
paths=context.resolveSourcePaths(state.project.inputs.sources);
items=flir_thermal.sourceFiles.readImages(paths,struct("SkipInvalid",false));
for k=1:numel(items)
    sourceId=state.project.inputs.sources(k).id; a=annotationFor(state.project.annotations.items,sourceId);items(k)=flir_thermal.thermalAnnotations.apply(items(k),a);
end
p=state.project.parameters; payload=flir_thermal.resultFiles.writeOutputs(items,struct("outputFolder",string(choice.Value),"format",p.exportFormat,"palette",p.palette,"colorMapping",p.colorMapping,"gammaValue",p.gammaValue,"range",[]));
state.project.results.lastExport=payload;context.appendStatus("Exported thermal images to "+string(choice.Value));
end

function a=annotationFor(items,id)
a=[];i=find(string({items.sourceId})==string(id),1);if ~isempty(i),a=items(i);end
end
