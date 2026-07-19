function view = present(applicationState)
%PRESENT Adapt runtime state into feature-owned presentation inputs.
%
% This is the only presentation boundary that knows the complete runtime
% state. Feature presenters receive only the values they display.
project = applicationState.project;
session = applicationState.session;
steps = project.annotations.steps;
referenceItem = session.cache.referenceItem;
currentItem = session.cache.currentItem;
previewResult = session.cache.previewResult;
previewMode = session.view.previewMode;

ready = ~isempty(referenceItem) && ~isempty(currentItem);
view = labkit.app.view.Snapshot();
view = view.enabled("applyMatch", ready);
view = view.enabled("undoHistory", ~isempty(steps));
view = view.enabled("resetHistory", ~isempty(steps));
view = view.enabled("exportImages", ready && ~isempty(steps));
view = view.include(image_match.imagePreview.present( ...
    steps, currentItem, previewResult, previewMode));
end
