function applicationState = add(applicationState, ~)
%ADD Create and select a centered ROI for the current image.
[annotation, ~] = roi_analyzer.roiLibrary.currentAnnotation(applicationState);
if strlength(annotation.sourceId) == 0
    return
end
imageSize = size(applicationState.session.cache.image);
roi = roi_analyzer.roiLibrary.emptyRoi();
roi.id = roi_analyzer.roiLibrary.nextId({annotation.rois.id}, "roi-");
roi.name = "ROI " + extractAfter(roi.id, "roi-");
roi.templateId = applicationState.project.annotations.templates(1).id;
roi.centerXY = [(imageSize(2) + 1) / 2, (imageSize(1) + 1) / 2];
annotation.rois(end + 1, 1) = roi;
applicationState = roi_analyzer.roiLibrary.storeAnnotation( ...
    applicationState, annotation);
applicationState.session.selection.roiIndex = numel(annotation.rois);
applicationState.session.selection.roiIndices = numel(annotation.rois);
end
