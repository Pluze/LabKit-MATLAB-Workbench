% App-owned runtime definition for labkit_FigureStudio_app. Expected caller:
% the public app entrypoint. Output is a declarative LabKit app definition;
% side effects are none.
function app = definition()
    app = labkit.app.Definition( ...
        Entrypoint="labkit_FigureStudio_app", AppId="figure_studio", ...
        Title="Figure Studio", Family="LabKit Core", ...
        AppVersion="0.10.1", Updated="2026-09-06", ...
        CreateState=@createInitialState, RefreshState=@refreshState, ...
        OnStart=@figure_studio.initializeWorkbench, ...
        Workbench=figure_studio.workbench.buildLayout(), ...
        PresentWorkbench=@figure_studio.workbench.present);
end

function state = createInitialState(context, initialInput)
if isempty(initialInput)
    project = figure_studio.initialData();
else
    project = initialInput;
end
state = struct("project", project, ...
    "session", figure_studio.createSession(project, context));
end

function state = refreshState(state, context)
state.session = figure_studio.createSession(state.project, context);
end
