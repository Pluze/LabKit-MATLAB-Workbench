function applicationState = selectionChanged( ...
        applicationState, ~, ~)
%SELECTIONCHANGED Reconcile source-derived result and output state.
% Called after the framework updates the source list or its visible
% selection. Source replacement rebuilds the decoded session before this
% callback; a selection-only change leaves a current result intact.
paths = applicationState.session.cache.sourcePaths;
if isempty(paths)
    if ~isempty(applicationState.project.inputs.sources)
        paths = labkit.app.source.paths( ...
            applicationState.project.inputs.sources);
    end
else
    paths = string(paths(:));
end
if strlength(applicationState.project.parameters.outputFolder) == 0 && ...
        ~isempty(paths)
    applicationState.project.parameters.outputFolder = ...
        string(fileparts(paths(1)));
end
end
