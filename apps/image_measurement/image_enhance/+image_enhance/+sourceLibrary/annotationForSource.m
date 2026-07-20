% App-owned implementation for image_enhance.sourceLibrary.annotationForSource within the image_enhance product workflow.
function annotation = annotationForSource(items, sourceId)
%ANNOTATIONFORSOURCE Return a sparse per-image annotation or its default.
index=find(string({items.sourceId})==string(sourceId),1);
if isempty(index)
    annotation=image_enhance.enhancementAnnotations.empty();
    annotation.sourceId=string(sourceId);
else
    annotation=items(index);
end
end
