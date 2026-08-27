% App-owned runtime definition for labkit_BatchImageCrop_app. Expected
% caller: the public app entrypoint. Output is a declarative LabKit app
% definition; side effects are none.
function app = definition()
    app = labkit.app.Definition(Entrypoint="labkit_BatchImageCrop_app", ...
        AppId="batch_crop", Title="Microscope Batch Image Crop", ...
        DisplayName="Batch Image Crop", Family="Image Measurement", ...
        AppVersion="1.10.2", Updated="2026-08-26", ...
        Requirements=labkit.contract.requirements("image", ">=2.0 <3"), ...
        CreateState=@createInitialState, RefreshState=@refreshState, ...
        Workbench=batch_crop.workbench.buildLayout(), PresentWorkbench=@batch_crop.workbench.present);
end

function state = createInitialState(context, initialInput)
if isempty(initialInput)
    project = batch_crop.initialData();
else
    project = initialInput;
end
state = struct("project", project, ...
    "session", batch_crop.createSession(project, context));
end

function state = refreshState(state, context)
state.session = batch_crop.createSession(state.project, context);
end
