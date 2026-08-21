% App-owned runtime definition for labkit_RHSPreview_app.
% Expected caller: the public app entrypoint. Output is a declarative LabKit
% app definition; side effects are none.
function app = definition()
    app = labkit.app.Definition(Entrypoint="labkit_RHSPreview_app", ...
        AppId="rhs_preview", Title="RHS Preview", DisplayName="RHS Preview", ...
        Family="Neurophysiology", AppVersion="1.7.0", Updated="2026-08-20", ...
        Requirements=labkit.contract.requirements("rhs", ">=1.0 <2"), ...
        CreateState=@createInitialState, RefreshState=@refreshState, ...
        Workbench=rhs_preview.workbench.buildLayout(), PresentWorkbench=@rhs_preview.workbench.present);
end

function state = createInitialState(context, initialInput)
if isempty(initialInput)
    project = rhs_preview.initialData();
else
    project = initialInput;
end
state = struct("project", project, ...
    "session", rhs_preview.createSession(project, context));
end

function state = refreshState(state, context)
state.session = rhs_preview.createSession(state.project, context);
end
