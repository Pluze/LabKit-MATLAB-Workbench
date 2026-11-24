function app = definition()
    app = labkit.app.Definition( ...
        Entrypoint="labkit_EMGReview_app", AppId="emg_review", ...
        Title="EMG Review", DisplayName="EMG Review", Family="Wearable", ...
        AppVersion="1.0.0", Updated="2026-11-23", ...
        Requirements=labkit.contract.requirements("biosignal", ">=3.1 <4"), ...
        CreateState=@createState, RefreshState=@refreshState, ...
        Workbench=emg_review.workbench.buildLayout(), ...
        PresentWorkbench=@emg_review.workbench.present);
end

function applicationState = createState(context, initialInput)
    project = initialInput;
    if isempty(project)
        project = struct('inputs', struct('sources', struct([])));
    end
    applicationState = struct('project', project, 'session', struct('revision', 0));
    applicationState = refreshState(applicationState, context);
end

function applicationState = refreshState(applicationState, ~)
    paths = labkit.app.source.paths(applicationState.project.inputs.sources);
    revision = applicationState.session.revision + 1;
    session = emg_review.sourceFiles.readSource(paths);
    session.revision = revision;
    applicationState.session = session;
end
