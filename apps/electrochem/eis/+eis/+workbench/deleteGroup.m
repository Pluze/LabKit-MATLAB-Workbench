function applicationState = deleteGroup(applicationState, ~)
%DELETEGROUP Delete the selected group and release its scans, retaining files.
if ~applicationState.project.parameters.groupingEnabled, return; end
groups = applicationState.project.groups;
groups(string({groups.name}) == applicationState.project.parameters.selectedGroup) = [];
applicationState.project.groups = groups;
choices = eis.workbench.groupChoices(groups);
applicationState.project.parameters.selectedGroup = choices(end);
end
