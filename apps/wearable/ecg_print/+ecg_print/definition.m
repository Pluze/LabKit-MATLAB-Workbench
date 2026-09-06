% App-owned runtime definition for labkit_ECGPrint_app. Expected caller: the
% public app entrypoint. Output is a declarative LabKit app definition; side
% effects are none.
function app = definition()
    app = labkit.app.Definition( ...
        Entrypoint="labkit_ECGPrint_app", AppId="ecg_print", ...
        Title="ECG Signal Print + SNR Explorer", DisplayName="ECG Print", ...
        Family="Wearable", AppVersion="2.2.1", Updated="2026-09-06", ...
        Requirements=labkit.contract.requirements( ...
            "biosignal", ">=3 <4"), ...
        CreateState=@createInitialState, RefreshState=@refreshState, ...
        Workbench=ecg_print.workbench.buildLayout(), ...
        PresentWorkbench=@ecg_print.workbench.present);
end

function state = createInitialState(context, initialInput)
if isempty(initialInput)
    project = ecg_print.initialData();
else
    project = initialInput;
end
session = ecg_print.createSession(project, context);
project = initializeAnalysisBand(project, session.cache.signal);
state = struct("project", project, "session", session);
end

function state = refreshState(state, context)
state.session = ecg_print.createSession(state.project, context);
state.project = initializeAnalysisBand( ...
    state.project, state.session.cache.signal);
end

function project = initializeAnalysisBand(project, signal)
isAutomatic = isfield(project.parameters, "analysisBandAutomatic") && ...
    project.parameters.analysisBandAutomatic;
if isAutomatic && ~isempty(signal)
    project.parameters.lowCut = 0;
    project.parameters.highCut = 0.5 * double(signal.fs);
end
end
