function applicationState = changeMode(applicationState, previewMode, ~)
%CHANGEMODE Store the selected preview mode declared by the plot area.
applicationState.session.view.previewMode = string(previewMode);
end
