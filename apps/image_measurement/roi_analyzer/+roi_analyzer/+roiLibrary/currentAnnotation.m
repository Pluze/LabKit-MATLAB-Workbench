function [annotation, sourceIndex] = currentAnnotation(applicationState)
%CURRENTANNOTATION Return the annotation for the selected decoded image.
sourceIndex = applicationState.session.selection.sourceIndex;
sources = applicationState.project.inputs.sources;
if sourceIndex < 1 || sourceIndex > numel(sources) || ...
        isempty(applicationState.session.cache.image)
    annotation = struct("sourceId", "", "rois", ...
        repmat(roi_analyzer.roiLibrary.emptyRoi(), 0, 1));
    return
end
annotation = roi_analyzer.roiLibrary.annotationForSource( ...
    applicationState.project.annotations.items, sources(sourceIndex).id);
end
