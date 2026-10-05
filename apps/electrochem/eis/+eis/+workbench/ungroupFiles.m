function applicationState = ungroupFiles(applicationState, ~)
%UNGROUPFILES Remove selected scans from their groups without removing sources.
if ~applicationState.project.parameters.groupingEnabled, return; end
indices = applicationState.session.selection.files.Indices;
if isempty(indices), return; end
sources = applicationState.project.inputs.sources;
ids = string({sources(indices).id});
groups = applicationState.project.groups;
for k = numel(groups):-1:1
    groups(k).sourceIds = groups(k).sourceIds(~ismember(groups(k).sourceIds, ids));
end
applicationState.project.groups = groups;
end
