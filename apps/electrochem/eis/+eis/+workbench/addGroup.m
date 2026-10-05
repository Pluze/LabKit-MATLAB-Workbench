function applicationState = addGroup(applicationState, callbackContext)
%ADDGROUP Create and select an empty group, ready to receive selected scans.
if ~applicationState.project.parameters.groupingEnabled, return; end
name = strip(string(applicationState.project.parameters.groupName));
groups = applicationState.project.groups;
if strlength(name) == 0 || any(eis.workbench.groupChoices(groups) == name)
    callbackContext.alert("Enter a new, nonempty group name.", "Add group");
    return
end
groups(end+1) = struct("name", name, "sourceIds", strings(1,0));
applicationState.project.groups = groups;
applicationState.project.parameters.selectedGroup = name;
applicationState.project.parameters.groupName = "";
end
