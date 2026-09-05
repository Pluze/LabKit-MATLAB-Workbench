classdef AutomaticInstrumentationSpec < matlab.unittest.TestCase
    %AUTOMATICINSTRUMENTATIONSPEC Prove Runtime-owned semantic event chains.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function plotOperationsRetainTheirFailureAndElapsedBoundary(testCase)
            % Oracle: a named failed copy has one terminal failure, and detached
            % plots still execute after close without touching a closed journal.
            runtime = instrumentationRuntime(testCase, @incrementProject, @presentProject);
            cleanup = onCleanup(@() runtime.close());
            testCase.verifyError(@() runtime.performPlotOperation( ...
                "plots.copy_main", @failPlotCopy), "probe:CopyFailed");
            records = runtime.diagnosticSnapshot().events;
            failed = oneRecord(records, "plots.copy_main.failed");
            testCase.verifyEqual(failed.operationResult, "failed");
            testCase.verifyGreaterThanOrEqual(failed.durationSeconds, 0);
            runtime.close();
            result = runtime.performPlotOperation("plots.studio_launch", @() 42);
            testCase.verifyEqual(result, 42);
            clear cleanup
        end

        function capturesSuccessfulPresentationOnlyAtTraceLevel(testCase)
            runtime = instrumentationRuntime( ...
                testCase, @incrementProject, @presentProject);
            cleanup = onCleanup(@() runtime.close());

            records = runtime.diagnosticSnapshot().events;
            testCase.verifyFalse(any(string({records.eventName}) == ...
                "presentation.rendered.started"));

            runtime.setTraceCapture(true);
            runtime.invokeAction("run");
            records = runtime.diagnosticSnapshot().events;
            action = records(string({records.eventName}) == ...
                "interaction.action_invoked.started");
            presentations = records(string({records.eventName}) == ...
                "presentation.rendered.started");
            callbackPresentation = presentations(end);
            completed = records(string({records.eventName}) == ...
                "presentation.rendered.completed");

            testCase.verifyNumElements(action, 1);
            testCase.verifyNumElements(presentations, 1);
            testCase.verifyNumElements(completed, 1);
            testCase.verifyEqual(callbackPresentation.parentOperationId, ...
                action.operationId);
            testCase.verifyEqual(callbackPresentation.rootActionId, ...
                action.rootActionId);
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
            records = runtime.diagnosticSnapshot().events;
            action = oneRecord(records, "interaction.action_invoked.started");
            presentation = oneRecord( ...
                records, "presentation.rendered.failed");
            actionFailure = oneRecord(records, "interaction.action_invoked.failed");

            testCase.verifyEqual( ...
                presentation.parentOperationId, action.operationId);
            testCase.verifyEqual( ...
                presentation.rootActionId, action.rootActionId);
            testCase.verifyEqual( ...
                presentation.operationResult, "failed");
            testCase.verifyEqual( ...
                presentation.stateDisposition, "notApplicable");
            testCase.verifyEqual( ...
                actionFailure.stateDisposition, "rolledBack");
            testCase.verifyEqual(runtime.State.project.count, 0);
            clear cleanup
        end

        function recordsNestedSourceDialogResultAndResourceOperations(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            writelines("synthetic summary", ...
                fullfile(folder, "summary.txt"));
            backend = struct("choose", @chooseContinue);
            initialProject = createProject();
            initialProject.folder = string(folder);
            runtime = instrumentationRuntime( ...
                testCase, @exerciseCapabilities, @presentProject, ...
                backend, initialProject);
            cleanup = onCleanup(@() runtime.close());

            runtime.invokeAction("run");
            records = runtime.diagnosticSnapshot().events;
            action = oneRecord( ...
                records, "interaction.action_invoked.started");
            expected = [
                "dialog.option_chosen.started"
                "resource.set.started"
                "resource.removed.started"
                ];

            for eventName = expected.'
                operations = records( ...
                    string({records.eventName}) == eventName);
                testCase.verifyNotEmpty(operations);
                testCase.verifyTrue(all( ...
                    string({operations.parentOperationId}) == ...
                        action.operationId));
                testCase.verifyTrue(all( ...
                    string({operations.rootActionId}) == ...
                        action.rootActionId));
            end
            testCase.verifyEqual(runtime.State.project.count, 1);
            clear cleanup
        end

        function recordsManagedInteractionAsTheRootAction(testCase)
            runtime = managedInteractionRuntime(testCase);
            cleanup = onCleanup(@() runtime.close());

            runtime.applyInteraction( ...
                "probeRectangle", "interactionChanged", [1 2 3 4]);
            records = runtime.diagnosticSnapshot().events;
            interaction = oneRecord( ...
                records, "interaction.managed_committed.started");
            interactionCompleted = oneRecord( ...
                records, "interaction.managed_committed.completed");

            testCase.verifyEqual( ...
                interactionCompleted.stateDisposition, "committed");
            testCase.verifyEqual(interactionCompleted.operationId, ...
                interaction.operationId);
            testCase.verifyEqual(runtime.State.project.count, 1);
            clear cleanup
        end
    end
end

function runtime = instrumentationRuntime( ...
        testCase, callback, presenter, backend, initialProject)
if nargin < 4
    backend = struct();
end
if nargin < 5
    initialProject = [];
end
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
    CreateState=@createInstrumentationState, ...
    PresentWorkbench=presenter);
runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...
    definition, initialProject, backend, ...
    [], ...
    JournalRoot=journalRoot);
end

function runtime = managedInteractionRuntime(testCase)
journalRoot = testCase.applyFixture( ...
    matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
rectangle = labkit.app.interaction.rectangle( ...
    "probeRectangle", @moveRectangle, Axis="main");
workspace = labkit.app.layout.workspace( ...
    labkit.app.layout.plotArea( ...
        "preview", @drawProbe, Interactions={rectangle}));
definition = labkit.app.Definition( ...
    Entrypoint="labkit_ManagedInstrumentationProbe_app", ...
    AppId="probe.managed-instrumentation", ...
    Title="Managed instrumentation probe", Family="Tests", ...
    AppVersion="1.0.0", Updated="2026-07-26", ...
    Requirements=[], ...
    Workbench=labkit.app.layout.workbench({}, Workspace=workspace), ...
    CreateState=@createInstrumentationState, ...
    PresentWorkbench=@presentManaged);
runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...
    definition, [], struct(), [], ...
    JournalRoot=journalRoot);
end

function project = createProject()
project = struct( ...
    "count", 0, "failPresentation", false, "folder", "");
end

function state = createInstrumentationState(~, initialInput)
if isempty(initialInput)
    project = createProject();
else
    project = initialInput;
end
state = struct("project", project, "session", struct());
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

function snapshot = presentManaged(~)
snapshot = labkit.app.view.Snapshot() ...
    .renderPlot("preview", struct()) ...
    .rectangle("probeRectangle", [1 2 3 4], ...
        ImageSize=[10 10], Enabled=true);
end

function applicationState = exerciseCapabilities( ...
        applicationState, callbackContext)
folder = applicationState.project.folder;
choice = callbackContext.chooseOption( ...
    "Continue synthetic operation?", ["continue", "cancel"], ...
    DefaultChoice="continue", CancelChoice="cancel");
if choice.Value ~= "continue"
    return;
end
callbackContext.setResource("probe", struct("ready", true), []);
callbackContext.removeResource("probe");
callbackContext.setResource("probe-clear", struct("ready", true), []);
callbackContext.removeResource("probe-clear");
source = labkit.app.source.record( ...
    "source-1", "input", fullfile(folder, "input.dat"));
labkit.app.source.paths(source);
applicationState.project.count = applicationState.project.count + 1;
end

function choice = chooseContinue(~, ~, ~, ~, ~)
choice = labkit.app.dialog.Choice("continue");
end

function applicationState = moveRectangle( ...
        applicationState, ~, ~)
applicationState.project.count = applicationState.project.count + 1;
end

function drawProbe(~, ~)
end

function record = oneRecord(records, eventName)
record = records(string({records.eventName}) == eventName);
assert(isscalar(record), "Expected one " + eventName + " record.");
end

function failPlotCopy()
error("probe:CopyFailed", "Synthetic clipboard failure.");
end
