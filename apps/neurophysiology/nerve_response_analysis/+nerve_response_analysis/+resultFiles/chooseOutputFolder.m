% App-owned implementation for nerve_response_analysis.resultFiles.chooseOutputFolder within the nerve_response_analysis product workflow.
function state = chooseOutputFolder(state, context)
%CHOOSEOUTPUTFOLDER Select the explicit analysis destination.
startPath = state.session.workflow.outputFolder;
if strlength(startPath) == 0
    startPath = pwd;
end
choice = context.chooseOutputFolder(startPath);
if choice.Cancelled
    state.session.workflow.lastAction = ...
        "Output folder selection cancelled";
    return;
end
state.session.workflow.outputFolder = string(choice.Value);
state.session.workflow.lastAction = "Selected output folder";
context.appendStatus( ...
    "Selected output folder: " + string(choice.Value));
end
