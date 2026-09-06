% App-owned runtime definition for labkit_ImageEnhance_app. Expected caller:
% the public app entrypoint. Output is a declarative LabKit app definition;
% side effects are none.
function app = definition()
    app = labkit.app.Definition(Entrypoint="labkit_ImageEnhance_app", ...
        AppId="image_enhance", Title="Paper Image Enhance", DisplayName="Image Enhance", ...
        Family="Image Measurement", AppVersion="1.9.3", Updated="2026-09-06", ...
        Requirements=labkit.contract.requirements("image", ">=2.0 <3"), ...
        CreateState=@createInitialState, RefreshState=@refreshState, ...
        Workbench=image_enhance.workbench.buildLayout(), PresentWorkbench=@image_enhance.workbench.present);
end

function state = createInitialState(context, initialInput)
if isempty(initialInput)
    project = image_enhance.initialData();
else
    project = initialInput;
end
state = struct("project", project, ...
    "session", image_enhance.createSession(project, context));
end

function state = refreshState(state, context)
state.session = image_enhance.createSession(state.project, context);
end
