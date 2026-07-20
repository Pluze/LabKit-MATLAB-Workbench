function state = clearOutputFolder(state, context)
%CLEAROUTPUTFOLDER Clear the current analysis destination.
state.session.workflow.outputFolder = "";
state.session.workflow.lastAction = "Cleared output folder";
context.appendStatus("Cleared output folder.");
end
