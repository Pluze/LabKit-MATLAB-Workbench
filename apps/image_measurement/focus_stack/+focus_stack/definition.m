% App-owned runtime definition for labkit_FocusStack_app. Expected caller:
% the public app entrypoint. Output is a declarative LabKit app definition;
% side effects are none.
function app = definition()
    app = labkit.app.Definition( ...
        Entrypoint="labkit_FocusStack_app", AppId="focus_stack", ...
        Title="Microscope Focus Stack Fusion", DisplayName="Focus Stack", ...
        Family="Image Measurement", AppVersion="1.8.0", Updated="2026-08-20", ...
        Requirements=labkit.contract.requirements("image", ">=2.0 <3"), ...
        CreateState=@createInitialState, RefreshState=@refreshState, ...
        Workbench=focus_stack.workbench.buildLayout(), ...
        PresentWorkbench=@focus_stack.workbench.present);
end

function state = createInitialState(context, initialInput)
if isempty(initialInput)
    project = focus_stack.initialData();
else
    project = initialInput;
end
state = struct("project", project, ...
    "session", focus_stack.createSession(project, context));
end

function state = refreshState(state, context)
state.session = focus_stack.createSession(state.project, context);
end
