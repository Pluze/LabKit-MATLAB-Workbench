% Private UI app helper. Expected caller: app runtime services that need the
% stored LabKit runtime from a figure. Input is a figure handle. Output is the
% runtime struct installed by labkit.ui.app.run.
function runtime = getAppRuntime(fig)
    if isempty(fig) || ~isvalid(fig) || ~isappdata(fig, appRuntimeKey())
        error('labkit:ui:app:MissingRuntime', ...
            'The figure does not have a LabKit app runtime.');
    end
    runtime = getappdata(fig, appRuntimeKey());
end
