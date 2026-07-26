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
            definition = probeDefinition(layout);
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
                definition, [], struct(), options, journal);
            cleanup = onCleanup(@() runtime.close());

            runtime.invokeAction("run");

            testCase.verifyEqual(runtime.StatusLog(end), "Legacy status.");
            events = runtime.diagnosticEvents();
            status = events(string({events.eventName}) == "status.appended");
            checkpoint = events(string({events.eventName}) == "probe.checkpoint");
            count = events(string({events.eventName}) == "probe.count");
            reported = events(string({events.eventName}) == "probe.operation.failed");
            testCase.verifyNumElements(status, 1);
            testCase.verifyEqual(status.message, "Legacy status.");
            testCase.verifyNumElements(checkpoint, 1);
            testCase.verifyEqual(checkpoint.attributes.enum, "checkpoint");
            testCase.verifyEqual(checkpoint.operationResult, "");
            testCase.verifyEqual(checkpoint.stateDisposition, "");
            testCase.verifyNumElements(count, 1);
            testCase.verifyEqual(count.attributes.enum, "count");
            testCase.verifyEqual(count.attributes.count, 2);
            testCase.verifyNumElements(reported, 1);
            testCase.verifyEqual(reported.operationResult, "failed");
            testCase.verifyEqual(reported.stateDisposition, "notApplicable");
            testCase.verifyEqual(reported.exception.identifier, "probe:ExpectedFailure");
            clear cleanup
        end

        function diagnosticRecorderBridgesAbandonedOperationsInMemory(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            options = labkit.app.diagnostic.Options( ...
                Level="verbose", ArtifactFolder=folder);
            recorder = labkit.app.internal.DiagnosticRecorder( ...
                probeDefinition(labkit.app.layout.workbench({})), options);
            cleanup = onCleanup(@() recorder.close());

            operation = recorder.begin("runtime.callback", "callback.run", ...
                "Dispatching callback.");
            testCase.verifyError(@() recorder.finish(operation, "completed"), ...
                "labkit:app:contract:InvalidValue");
            recorder.close();
            events = recorder.events();
            abandoned = events(string({events.eventName}) == "callback.run.abandoned");

            testCase.verifyNumElements(abandoned, 1);
            testCase.verifyEqual(abandoned.operationResult, "abandoned");
            testCase.verifyEqual(abandoned.stateDisposition, "unknown");
            testCase.verifyFalse(isfile(fullfile(folder, "events.jsonl")));
            testCase.verifyFalse(isfile(fullfile(folder, "active-operation.json")));
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
