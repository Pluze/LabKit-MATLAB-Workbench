function applicationState = changePosition(applicationState, value, ~)
%CHANGEPOSITION Store committed ROI center slots in source coordinates.
[annotation, ~] = roi_analyzer.roiLibrary.currentAnnotation(applicationState);
scale = applicationState.session.cache.previewScale;
selectedIndex = applicationState.session.selection.roiIndex;
if isstruct(value) && isscalar(value) && isfield(value, "points")
    points = double(value.points);
    if isfield(value, "selectedIndex")
        selectedIndex = double(value.selectedIndex);
    end
    if isfield(value, "selectedIndices")
        applicationState.session.selection.roiIndices = ...
            double(value.selectedIndices(:).');
    end
else
    points = double(value);
end
if ~isequal(size(points), [numel(annotation.rois) 2]) || ...
        any(~isfinite(points), "all") || ~isfinite(scale) || scale <= 0
    return
end
points = (points - 0.5) ./ scale + 0.5;
templates = applicationState.project.annotations.templates;
selected = roi_analyzer.roiLibrary.selectedIndices( ...
    applicationState.session.selection, numel(annotation.rois));
if numel(selected) > 1
    [groupCenters, fits] = roi_analyzer.roiLibrary.fitCentersToImage( ...
        points(selected, :), annotation.rois(selected), templates, ...
        size(applicationState.session.cache.image));
    if fits
        points(selected, :) = groupCenters;
    end
end
for index = 1:numel(annotation.rois)
    match = find(string({templates.id}) == annotation.rois(index).templateId, 1);
    geometry = templates(match);
    position = [points(index, :) - (double(geometry.size) - 1) ./ 2, ...
        double(geometry.size)];
    position = roi_analyzer.roiLibrary.normalizePosition(position, ...
        geometry.shape, size(applicationState.session.cache.image));
    annotation.rois(index).centerXY = ...
        position(1:2) + (position(3:4) - 1) ./ 2;
end
applicationState = roi_analyzer.roiLibrary.storeAnnotation( ...
    applicationState, annotation);
applicationState.session.selection.roiIndex = min(max(1, ...
    round(selectedIndex)), numel(annotation.rois));
end
