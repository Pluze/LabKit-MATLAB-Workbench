classdef LegacyDiagnosticsCharacterizationSpec < matlab.unittest.TestCase
    %LEGACYDIAGNOSTICSCHARACTERIZATIONSPEC Freeze pre-migration diagnostic behavior.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function legacyCallbackOperationsRemainAvailableUntilConsumerMigration(testCase)
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.button("run", "Run", @runProbe, ...
                    Tooltip="Run the probe.")});
            runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
                probeDefinition(layout));
            cleanup = onCleanup(@() runtime.close());

            runtime.invokeAction("run");

            testCase.verifyEqual(runtime.StatusLog(end), "Legacy status.");
            testCase.verifyNotEmpty(runtime.diagnosticEvents());
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
