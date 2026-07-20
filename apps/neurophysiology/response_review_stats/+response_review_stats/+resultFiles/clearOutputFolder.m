% App-owned implementation for response_review_stats.resultFiles.clearOutputFolder within the response_review_stats product workflow.
function state = clearOutputFolder(state, context)
%CLEAROUTPUTFOLDER Clear the current metrics destination.
state.session.workflow.outputFolder = "";
state.session.workflow.lastAction = "Cleared output folder";
context.appendStatus("Cleared output folder.");
end
