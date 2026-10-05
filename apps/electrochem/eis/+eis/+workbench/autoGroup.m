function applicationState = autoGroup(applicationState, callbackContext)
%AUTOGROUP Add unassigned scans by exact filename prefix without moving members.
if ~applicationState.project.parameters.groupingEnabled, return; end
[groups, rejected] = eis.sourceFiles.identifyGroups( ...
    applicationState.session.cache.items, applicationState.project.inputs.sources, ...
    applicationState.project.groups);
applicationState.project.groups = groups;
choices = eis.workbench.groupChoices(groups);
if ~any(string({groups.name}) == applicationState.project.parameters.selectedGroup)
    applicationState.project.parameters.selectedGroup = choices(end);
end
for k = 1:numel(rejected)
    callbackContext.log("warning", "eis.grouping.autorejected", ...
        "A filename group was not assigned because its frequency grids cannot be paired.", ...
        Exception=rejected{k});
end
if ~isempty(rejected)
    callbackContext.inform(string(numel(rejected)) + ...
        " filename group(s) could not be paired by frequency. Their files remain unassigned; " + ...
        "review the scan grids before assigning them manually.", "Auto-grouping");
end
end
