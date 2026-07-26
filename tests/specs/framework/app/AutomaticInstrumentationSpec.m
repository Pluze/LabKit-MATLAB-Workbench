classdef AutomaticInstrumentationSpec < matlab.unittest.TestCase
    %AUTOMATICINSTRUMENTATIONSPEC Prove Runtime-owned semantic event chains.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function nestsPresentationUnderConstructionAndCallbacks(testCase)
            runtime = instrumentationRuntime( ...
                testCase, @incrementProject, @presentProject);
            cleanup = onCleanup(@() runtime.close());

            records = runtime.diagnosticEvents();
            construction = oneRecord(records, "runtime.construct.started");
            initialPresentation = ...
                oneRecord(records, "presentation.rendered.started");
            testCase.verifyEqual( ...
                initialPresentation.parentOperationId, ...
                construction.operationId);
            testCase.verifyEqual( ...
                initialPresentation.rootActionId, construction.rootActionId);

            runtime.invokeAction("run");
            records = runtime.diagnosticEvents();
            callbacks = records(string({records.eventName}) == ...
                "callback.pressed.started");
            presentations = records(string({records.eventName}) == ...
                "presentation.rendered.started");
            callbackPresentation = presentations(end);
            completed = records(string({records.eventName}) == ...
                "presentation.rendered.completed");

            testCase.verifyNumElements(callbacks, 1);
            testCase.verifyNumElements(presentations, 2);
            testCase.verifyNumElements(completed, 2);
            testCase.verifyEqual(callbackPresentation.parentOperationId, ...
                callbacks.operationId);
            testCase.verifyEqual(callbackPresentation.rootActionId, ...
                callbacks.rootActionId);
            testCase.verifyEqual(completed(end).operationResult, "completed");
            testCase.verifyEqual( ...
                completed(end).stateDisposition, "notApplicable");
            clear cleanup
        end

        function recordsFailedPresentationInsideOneRolledBackCallback(testCase)
            runtime = instrumentationRuntime( ...
                testCase, @requestFailedPresentation, @presentProject);
            cleanup = onCleanup(@() runtime.close());

            testCase.verifyError(@() runtime.invokeAction("run"), ...
                "labkit:app:runtime:ActionFailed");
            records = runtime.diagnosticEvents();
            callback = oneRecord(records, "callback.pressed.started");
            presentation = oneRecord( ...
                records, "presentation.rendered.failed");
            callbackFailure = oneRecord(records, "callback.pressed.failed");

            testCase.verifyEqual( ...
                presentation.parentOperationId, callback.operationId);
            testCase.verifyEqual( ...
                presentation.rootActionId, callback.rootActionId);
            testCase.verifyEqual( ...
                presentation.operationResult, "failed");
            testCase.verifyEqual( ...
                presentation.stateDisposition, "notApplicable");
            testCase.verifyEqual( ...
                callbackFailure.stateDisposition, "rolledBack");
            testCase.verifyEqual(runtime.State.project.count, 0);
            clear cleanup
        end

        function recordsProjectSaveAndRestoreTransactions(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            runtime = instrumentationRuntime( ...
                testCase, @incrementProject, @presentProject);
            cleanup = onCleanup(@() runtime.close());
            projectFile = fullfile(folder, "project.mat");

            runtime.saveProject(runtime.State, projectFile);
            runtime.invokeAction("run");
            runtime.restoreProject(projectFile);
            records = runtime.diagnosticEvents();
            saved = oneRecord(records, "project.saved.completed");
            restoredStart = oneRecord(records, "project.restored.started");
            restored = oneRecord(records, "project.restored.completed");
            presentations = records(string({records.eventName}) == ...
                "presentation.rendered.started");
            restorePresentation = presentations( ...
                string({presentations.parentOperationId}) == ...
                    restoredStart.operationId);

            testCase.verifyEqual(saved.operationResult, "completed");
            testCase.verifyEqual(saved.stateDisposition, "committed");
            testCase.verifyEqual(restored.operationResult, "completed");
            testCase.verifyEqual(restored.stateDisposition, "committed");
            testCase.verifyNumElements(restorePresentation, 1);
            testCase.verifyEqual(restorePresentation.rootActionId, ...
                restoredStart.rootActionId);
            testCase.verifyEqual(runtime.State.project.count, 0);
            clear cleanup
        end
    end
end

function runtime = instrumentationRuntime(testCase, callback, presenter)
journalRoot = testCase.applyFixture( ...
    matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
layout = labkit.app.layout.workbench({ ...
    labkit.app.layout.button( ...
        "run", "Run", callback, Tooltip="Run instrumentation probe.")});
definition = labkit.app.Definition( ...
    Entrypoint="labkit_AutomaticInstrumentationProbe_app", ...
    AppId="probe.automatic-instrumentation", ...
    Title="Automatic instrumentation probe", Family="Tests", ...
    AppVersion="1.0.0", Updated="2026-07-26", ...
    Requirements=[], Workbench=layout, ...
    ProjectSchema=labkit.app.project.Schema( ...
        Version=1, Create=@createProject, Validate=@validateProject), ...
    PresentWorkbench=presenter);
runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
    definition, [], struct(), labkit.app.diagnostic.Options(), [], ...
    JournalRoot=journalRoot);
end

function project = createProject()
project = struct("count", 0, "failPresentation", false);
end

function accepted = validateProject(project)
accepted = isstruct(project) && isscalar(project) && ...
    isequal(string(fieldnames(project)), ["count"; "failPresentation"]) && ...
    isnumeric(project.count) && isscalar(project.count) && ...
    isfinite(project.count) && ...
    islogical(project.failPresentation) && ...
    isscalar(project.failPresentation);
end

function applicationState = incrementProject(applicationState, ~)
applicationState.project.count = applicationState.project.count + 1;
end

function applicationState = requestFailedPresentation(applicationState, ~)
applicationState.project.count = applicationState.project.count + 1;
applicationState.project.failPresentation = true;
end

function snapshot = presentProject(applicationState)
if applicationState.project.failPresentation
    error("probe:PresentationFailure", ...
        "Intentional presentation failure.");
end
snapshot = labkit.app.view.Snapshot();
end

function record = oneRecord(records, eventName)
record = records(string({records.eventName}) == eventName);
assert(isscalar(record), "Expected one " + eventName + " record.");
end
