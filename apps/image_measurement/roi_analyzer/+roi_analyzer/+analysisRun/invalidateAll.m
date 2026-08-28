function state = invalidateAll(state)
%INVALIDATEALL Clear measurements after shared analysis meaning changes.
for k = 1:numel(state.project.results.items)
    state.project.results.items(k).roiFingerprint = "";
    state.project.results.items(k).summary = table();
    state.project.results.items(k).metrics = table();
end
state.project.results.lastExportPath = "";
end
