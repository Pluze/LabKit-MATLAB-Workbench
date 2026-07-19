function state=exportImages(state,context)
%EXPORTIMAGES Render every source with its committed enhancement history.
if isempty(state.project.inputs.sources)
    context.alert("Load images before exporting.","No images loaded"); return
end
choice=context.chooseOutputFolder(state.project.parameters.outputFolder);
if choice.Cancelled,return,end
folder=string(choice.Value); state.project.parameters.outputFolder=folder;
items=image_enhance.sourceFiles.readImages(context.resolveSourcePaths(state.project.inputs.sources));
if state.project.parameters.batchMode
    steps=state.project.annotations.sharedSteps; itemSteps={};
else
    steps=repmat(image_enhance.analysisRun.emptyStep(),0,1); itemSteps=cell(numel(items),1);
    for k=1:numel(items)
        annotation=image_enhance.sourceLibrary.annotationForSource(state.project.annotations.items,state.project.inputs.sources(k).id);
        itemSteps{k}=annotation.steps; items(k).whiteRoi=annotation.whiteRoi;
    end
end
opts=struct("outputFolder",folder,"format",state.project.parameters.exportFormat,"itemSteps",{itemSteps});
payload=image_enhance.resultFiles.writeOutputs(items,steps,opts);
state.project.results.lastExport=payload;
context.appendStatus("Exported enhanced images to "+folder+".");
end
