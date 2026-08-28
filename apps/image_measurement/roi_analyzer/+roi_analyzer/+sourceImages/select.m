function applicationState = select(applicationState, selection, callbackContext)
%SELECT Lazily load the selected image and restore its ROI selection.
applicationState.project.annotations.items = reconcileAnnotations( ...
    applicationState.project.annotations.items, ...
    applicationState.project.inputs.sources);
applicationState.project.results.items = reconcileResults( ...
    applicationState.project.results.items, ...
    applicationState.project.inputs.sources);
if isempty(selection.Indices)
    applicationState.session = roi_analyzer.createSession( ...
        roi_analyzer.initialData(), callbackContext);
    return
end
index = selection.Indices(1);
sources = applicationState.project.inputs.sources;
if index > numel(sources)
    return
end
try
    applicationState.session.cache = ...
        roi_analyzer.sourceImages.loadSource(sources(index));
catch ME
    callbackContext.log("error", ...
        "roi_analyzer.sourceimages.select.exception", "Load image preview", ...
        Category="failure", Audience="developer", Exception=ME);
    callbackContext.alert(ME.message, "Could not load image");
    return
end
applicationState.session.selection.sourceIndex = index;
annotation = roi_analyzer.roiLibrary.annotationForSource( ...
    applicationState.project.annotations.items, sources(index).id);
originalRois = annotation.rois;
resolved = roi_analyzer.roiTemplates.resolve(annotation.rois, ...
    applicationState.project.annotations.templates, ...
    size(applicationState.session.cache.image));
for roiIndex = 1:numel(annotation.rois)
    annotation.rois(roiIndex).centerXY = resolved(roiIndex).centerXY;
end
if ~isequaln(annotation.rois, originalRois)
    applicationState = roi_analyzer.roiLibrary.storeAnnotation( ...
        applicationState, annotation);
end
applicationState.session.selection.roiIndex = double(~isempty(annotation.rois));
applicationState.session.selection.roiIndices = ...
    applicationState.session.selection.roiIndex;
applicationState.session.selection.roiCells = ...
    labkit.app.event.TableCellSelection(zeros(0, 2));
end

function items = reconcileAnnotations(items, sources)
current = items;
template = struct("sourceId", "", "rois", ...
    repmat(roi_analyzer.roiLibrary.emptyRoi(), 0, 1));
items = repmat(template, numel(sources), 1);
for k = 1:numel(sources)
    items(k) = roi_analyzer.roiLibrary.annotationForSource( ...
        current, sources(k).id);
end
end

function items = reconcileResults(items, sources)
current = items;
template = struct("sourceId", "", "roiFingerprint", "", ...
    "summary", table(), "metrics", table());
items = repmat(template, numel(sources), 1);
for k = 1:numel(sources)
    match = find(string({current.sourceId}) == string(sources(k).id), 1);
    if isempty(match)
        items(k) = template;
        items(k).sourceId = string(sources(k).id);
    else
        items(k) = current(match);
    end
end
end
