% App-owned runtime definition for labkit_ImageMatch_app. Expected caller:
% the public app entrypoint. Output is a declarative LabKit app definition;
% side effects are none.
function app = definition()
    app = labkit.app.Definition( ...
        Entrypoint="labkit_ImageMatch_app", AppId="image_match", ...
        Title="Paper Image Match", DisplayName="Image Match", ...
        Family="Image Measurement", AppVersion="1.9.0", Updated="2026-08-20", ...
        Requirements=labkit.contract.requirements("image", ">=2.0 <3"), ...
        CreateState=@createInitialState, RefreshState=@refreshState, ...
        Workbench=image_match.workbench.buildLayout(), ...
        PresentWorkbench=@image_match.workbench.present);
end

function state = createInitialState(context, initialInput)
if isempty(initialInput)
    project = image_match.initialData();
else
    project = initialInput;
end
state = struct("project", project, ...
    "session", image_match.createSession(project, context));
end

function state = refreshState(state, context)
state.session = image_match.createSession(state.project, context);
end
