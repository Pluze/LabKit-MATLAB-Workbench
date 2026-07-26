classdef LegacyDiagnosticsCharacterizationSpec < matlab.unittest.TestCase
    %LEGACYDIAGNOSTICSCHARACTERIZATIONSPEC Freeze pre-migration diagnostic behavior.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function legacyCallbackOperationsRemainAvailableUntilConsumerMigration(testCase)
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.button("run", "Run", @runProbe, ...
                    Tooltip="Run the probe.")});
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            options = labkit.app.diagnostic.Options( ...
                Level="verbose", ArtifactFolder=folder);
            runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
                probeDefinition(layout), [], struct(), options);
            cleanup = onCleanup(@() runtime.close());

            runtime.invokeAction("run");

            testCase.verifyEqual(runtime.StatusLog(end), "Legacy status.");
            events = runtime.diagnosticEvents();
            checkpoint = events(string({events.Category}) == "app" & ...
                string({events.TargetId}) == "probe.checkpoint" & ...
                string({events.Signal}) == "checkpoint" & ...
                string({events.Outcome}) == "completed");
            count = events(string({events.Category}) == "app" & ...
                string({events.TargetId}) == "probe.count" & ...
                string({events.Signal}) == "count" & ...
                string({events.Outcome}) == "completed");
            reported = events(string({events.Category}) == "reportedError" & ...
                string({events.TargetId}) == "probe.operation" & ...
                string({events.Signal}) == "reported" & ...
                string({events.Outcome}) == "reported");
            testCase.verifyNumElements(checkpoint, 1);
            testCase.verifyNumElements(count, 1);
            testCase.verifyEqual(count.Count, 2);
            testCase.verifyNumElements(reported, 1);
            testCase.verifyEqual(reported.ErrorId, "probe:ExpectedFailure");
            clear cleanup
        end

        function verboseRecorderKeepsAnAbandonedOperationMarker(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            options = labkit.app.diagnostic.Options( ...
                Level="verbose", ArtifactFolder=folder);
            recorder = labkit.app.internal.DiagnosticRecorder( ...
                probeDefinition(labkit.app.layout.workbench({})), options);
            cleanup = onCleanup(@() recorder.close());

            recorder.begin("callback", "run", "pressed");

            testCase.verifyTrue(isfile(fullfile(folder, "active-operation.json")));
            clear cleanup
        end
    end
end

function state = runProbe(state, callbackContext)
callbackContext.appendStatus("Legacy status.");
callbackContext.diagnosticCheckpoint("probe.checkpoint");
callbackContext.diagnosticCount("probe.count", 2);
try
    error("probe:ExpectedFailure", "Expected diagnostic failure.");
catch exception
    callbackContext.reportError("probe.operation", exception);
end
end

function definition = probeDefinition(layout)
definition = labkit.app.Definition( ...
    "Entrypoint", "labkit_LegacyDiagnosticsProbe_app", ...
    "AppId", "probe.legacy-diagnostics", "Title", "Legacy diagnostics probe", ...
    "Family", "Tests", "AppVersion", "1.0.0", "Updated", "2026-07-25", ...
    "Requirements", [], "Workbench", layout);
end
