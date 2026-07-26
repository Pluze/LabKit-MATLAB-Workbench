% App-owned implementation for response_review_stats.resultFiles.clearOutputFolder within the response_review_stats product workflow.
function state = clearOutputFolder(state, context)
%CLEAROUTPUTFOLDER Clear the current metrics destination.
state.session.workflow.outputFolder = "";
state.session.workflow.lastAction = "Cleared output folder";
context.log("info", "response_review_stats.resultfiles.clearoutputfolder.status", ...
    "Cleared the output folder.");
end
