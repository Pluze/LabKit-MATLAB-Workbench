% App-owned implementation for gait_analysis.resultFiles.chooseFolder within the gait_analysis product workflow.
function applicationState = chooseFolder(applicationState, callbackContext)
%CHOOSEFOLDER Select the destination for the gait CSV set.
choice = callbackContext.chooseOutputFolder( ...
    applicationState.session.workflow.outputFolder);
if choice.Cancelled
    callbackContext.log("info", "gait_analysis.resultfiles.choosefolder.status", "Output folder selection cancelled.");
    return
end
applicationState.session.workflow.outputFolder = string(choice.Value);
callbackContext.log("info", "gait_analysis.resultfiles.choosefolder.status",  ...
    "Selected the gait output folder.");
end
