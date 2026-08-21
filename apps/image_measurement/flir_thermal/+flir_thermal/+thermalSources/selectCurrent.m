% App-owned implementation for flir_thermal.thermalSources.selectCurrent within the flir_thermal product workflow.
function applicationState = selectCurrent( ...
        applicationState, selection, callbackContext)
%SELECTCURRENT Reconcile annotations and decode the selected FLIR source.
sources = applicationState.project.inputs.sources;
annotations = applicationState.project.annotations.items;
sourceIds = strings(1, 0);
if ~isempty(sources)
    sourceIds = string({sources.id});
end
annotationIds = strings(1, 0);
if ~isempty(annotations)
    annotationIds = string({annotations.sourceId});
    annotations(~ismember(annotationIds, sourceIds)) = [];
end
sourceSetChanged = ~isequal(sort(sourceIds), sort(annotationIds));
applicationState.project.annotations.items = annotations;

if isempty(sources)
    applicationState.session.selection.currentIndex = 0;
    applicationState.session.selection.thermalSources = ...
        labkit.app.event.ListSelection();
    applicationState.session.cache.currentItem = [];
    applicationState = invalidateResults(applicationState);
    callbackContext.log("info", ...
        "flir_thermal.thermalsources.selectcurrent.cleared", ...
        "Cleared loaded FLIR files.");
    return
end

index = selectedIndex(selection, sources);
try
    item = loadItem(sources(index), annotations);
catch ME
    callbackContext.log("error", "flir_thermal.thermalsources.selectcurrent.exception", "Load selected FLIR image", ...
        Category="failure", Audience="developer", Exception=ME);
    callbackContext.alert(ME.message, "Could not load FLIR image");
    return
end
applicationState.session.selection.currentIndex = index;
applicationState.session.selection.thermalSources = ...
    labkit.app.event.ListSelection( ...
        Ids=string(sources(index).id), Indices=index);
applicationState.session.cache.currentItem = item;
applicationState = ...
    flir_thermal.thermalSources.storeCurrentAnnotation( ...
        applicationState, item);
if strlength(applicationState.project.parameters.outputFolder) == 0
    paths = labkit.app.source.paths(sources);
    if ~isempty(paths)
        applicationState.project.parameters.outputFolder = ...
            string(fullfile(fileparts(paths(1)), "flir_thermal"));
    end
end
if sourceSetChanged
    applicationState = invalidateResults(applicationState);
end
callbackContext.log("info", ...
    "flir_thermal.thermalsources.selectcurrent.selected", sprintf( ...
    "Selected FLIR image %d of %d.", index, numel(sources)));
end

function index = selectedIndex(selection, sources)
index = 1;
if ~isempty(selection.Ids)
    match = find(string({sources.id}) == string(selection.Ids(1)), 1);
    if ~isempty(match)
        index = match;
        return
    end
end
if ~isempty(selection.Indices)
    index = min(numel(sources), max(1, selection.Indices(1)));
end
end

function item = loadItem(source, annotations)
paths = labkit.app.source.paths(source);
items = flir_thermal.sourceFiles.readImages( ...
    paths, struct("SkipInvalid", false));
if isempty(items)
    error("flir_thermal:UnreadableSource", ...
        "The selected FLIR source could not be decoded.");
end
annotation = [];
if ~isempty(annotations)
    match = find(string({annotations.sourceId}) == string(source.id), 1);
    if ~isempty(match)
        annotation = annotations(match);
    end
end
item = flir_thermal.thermalAnnotations.apply(items(1), annotation);
end

function applicationState = invalidateResults(applicationState)
applicationState.project.results.lastExport = [];
applicationState.project.results.resultManifestPath = "";
end
