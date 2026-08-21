% App-owned runtime definition for labkit_DICPreprocess_app. Expected caller:
% the public app entrypoint. Output is a declarative LabKit app definition;
% side effects are none.
function app = definition()
    app = labkit.app.Definition(Entrypoint="labkit_DICPreprocess_app", ...
        AppId="dic_preprocess", Title="DIC Image Preprocess", ...
        DisplayName="DIC Preprocess", Family="DIC", AppVersion="1.8.0", ...
        Updated="2026-08-20", Requirements=labkit.contract.requirements("image", ">=2.0 <3"), ...
        CreateState=@createInitialState, RefreshState=@refreshState, ...
        Workbench=dic_preprocess.workbench.buildLayout(), PresentWorkbench=@dic_preprocess.workbench.present);
end

function state = createInitialState(context, initialInput)
if isempty(initialInput)
    project = dic_preprocess.initialData();
else
    project = initialInput;
end
state = struct("project", project, ...
    "session", dic_preprocess.createSession(project, context));
end

function state = refreshState(state, context)
state.session = dic_preprocess.createSession(state.project, context);
end
