function state=changeWhiteRoi(state,position,~)
index=state.session.selection.currentIndex;
if index<1 || index>numel(state.project.inputs.sources),return,end
sourceId=state.project.inputs.sources(index).id;
annotation=image_enhance.sourceLibrary.annotationForSource( ...
    state.project.annotations.items,sourceId);
annotation.whiteRoi=double(position)./max(eps,state.session.cache.previewScale);
state.project.annotations.items=image_enhance.sourceLibrary.storeAnnotation( ...
    state.project.annotations.items,annotation);
end
