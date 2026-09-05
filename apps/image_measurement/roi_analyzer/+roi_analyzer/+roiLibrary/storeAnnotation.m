function state = storeAnnotation(state, annotation)
%STOREANNOTATION Replace one source-owned ROI collection.
items = state.project.annotations.items;
match = find(string({items.sourceId}) == string(annotation.sourceId), 1);
if isempty(match)
    items(end + 1, 1) = annotation;
else
    items(match) = annotation;
end
state.project.annotations.items = items;
state.project.results = roi_analyzer.analysisRun.invalidate(state.project.results, annotation.sourceId);
end
