% App-owned implementation for gait_analysis.resultFiles.chooseFolder within the gait_analysis product workflow.
function applicationState = chooseFolder(applicationState, callbackContext)
%CHOOSEFOLDER Select the destination for the gait CSV set.
choice = callbackContext.chooseOutputFolder( ...
    applicationState.session.workflow.outputFolder);
if choice.Cancelled
    callbackContext.appendStatus("Output folder selection cancelled.");
    return
end
applicationState.session.workflow.outputFolder = string(choice.Value);
callbackContext.appendStatus( ...
    "Output folder: " + string(choice.Value));
end
