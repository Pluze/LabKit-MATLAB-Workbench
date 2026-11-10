% App-owned runtime definition for labkit_ECGPrint_app. Expected caller: the
% public app entrypoint. Output is a declarative LabKit app definition; side
% effects are none.
function app = definition()
    app = labkit.app.Definition( ...
        Entrypoint="labkit_ECGPrint_app", AppId="ecg_print", ...
        Title="ECG Print · ECGNExT Beat Analysis", DisplayName="ECG Print", ...
        Family="Wearable", AppVersion="4.0.0", Updated="2026-11-10", ...
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
state = struct("project", project, "session", session);
state = ecg_print.analysisRun.resetRange(state);
end

function state = refreshState(state, context)
revision = state.session.cache.plotViewRevision + 1;
state.session = ecg_print.createSession(state.project, context);
state.session.cache.plotViewRevision = revision;
state = ecg_print.analysisRun.resetRange(state);
end
