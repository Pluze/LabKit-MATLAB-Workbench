function state=selectPreview(state,selection,context)
%SELECTPREVIEW Lazily decode the selected source after fileList commits it.
if isempty(selection.Indices),return,end
index=selection.Indices(1);
if index>numel(state.project.inputs.sources),return,end
source=state.project.inputs.sources(index);
items=image_enhance.sourceFiles.readImages(context.resolveSourcePaths(source));
if isempty(items),return,end
[preview,scale]=image_enhance.imagePreview.presentationData.previewImage(items(1).image);
state.session.selection.currentIndex=index;
state.session.cache.sourceId=string(source.id);
state.session.cache.item=items(1);
state.session.cache.previewSource=preview;
state.session.cache.previewScale=scale;
annotation=image_enhance.sourceLibrary.annotationForSource(state.project.annotations.items,source.id);
steps=activeSteps(state,annotation);
state.session.cache.previewResult=image_enhance.analysisRun.previewResult(preview,steps,annotation.whiteRoi,scale);
state.session.cache.previewResultKey="selected";
end

function steps=activeSteps(state,annotation)
if state.project.parameters.batchMode,steps=state.project.annotations.sharedSteps;else,steps=annotation.steps;end
end
