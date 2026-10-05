function applicationState = assignGroup(applicationState, callbackContext)
%ASSIGNGROUP Move selected files into the named group after grid validation.
if ~applicationState.project.parameters.groupingEnabled, return; end
indices = applicationState.session.selection.files.Indices;
if isempty(indices)
    callbackContext.alert("Select files in the Files list first.", "Groups");
    return
end
groups = applicationState.project.groups;
existing = find(string({groups.name}) == applicationState.project.parameters.selectedGroup, 1);
if isempty(existing)
    callbackContext.alert("Create or select a target group first.", "Groups");
    return
end
sources = applicationState.project.inputs.sources;
ids = string({sources(indices).id});
ids = unique([groups(existing).sourceIds(:); ids(:)], "stable").';
[~, positions] = ismember(ids, string({sources.id}));
try
    eis.analysisRun.groupCoordinates(applicationState.session.cache.items(positions), ...
        "Zreal", "-Zimag", "Ω");
catch exception
    if ~startsWith(string(exception.identifier), "eis:"), rethrow(exception); end
    callbackContext.log("warning", "eis.grouping.rejected", ...
        "Scan grouping rejected because frequency grids cannot be paired.", Exception=exception);
    callbackContext.alert(string(exception.message), "Cannot group scans");
    return
end
for k = numel(groups):-1:1
    groups(k).sourceIds = groups(k).sourceIds(~ismember(groups(k).sourceIds, ids));
end
groups(existing).sourceIds = ids;
applicationState.project.groups = groups;
end
