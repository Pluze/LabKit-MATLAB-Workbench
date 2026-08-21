classdef SemanticDiagnosticsSpec < matlab.unittest.TestCase
    %SEMANTICDIAGNOSTICSSPEC Verify App-owned semantic diagnostic events.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function semanticLogsDriveStatusAndDeveloperEvents(testCase)
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.button("run", "Run", @runProbe, ...
                    Tooltip="Run the probe.")});
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = probeDefinition(layout);
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...
                definition, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());

            runtime.invokeAction("run");

            testCase.verifyEqual(runtime.CurrentStatus, "Semantic status.");
            testCase.verifySize(runtime.CurrentStatus, [1 1]);
            events = runtime.diagnosticSnapshot().events;
            status = events(string({events.eventName}) == "probe.status");
            checkpoint = events(string({events.eventName}) == "probe.checkpoint");
            count = events(string({events.eventName}) == "probe.count");
            reported = events(string({events.eventName}) == "probe.operation.failed");
            testCase.verifyNumElements(status, 1);
            testCase.verifyEqual(status.message, "Semantic status.");
            testCase.verifyNumElements(checkpoint, 1);
            testCase.verifyEqual(checkpoint.attributes.enum, "checkpoint");
            testCase.verifyEqual(checkpoint.operationResult, "");
            testCase.verifyEqual(checkpoint.stateDisposition, "");
            testCase.verifyNumElements(count, 1);
            testCase.verifyEqual(count.attributes.enum, "count");
            testCase.verifyEqual(count.attributes.count, 2);
            testCase.verifyNumElements(reported, 1);
            testCase.verifyEqual(reported.operationResult, "");
            testCase.verifyEqual(reported.stateDisposition, "");
            testCase.verifyEqual(reported.exception.identifier, "probe:ExpectedFailure");
            clear cleanup
        end

        function streamClosesAbandonedOperationsInMemory(testCase)
            stream = labkit.app.internal.diagnostics.SessionEventStream( ...
                probeDefinition(labkit.app.layout.workbench({})));
            cleanup = onCleanup(@() stream.close());

            operation = stream.begin("runtime.callback", "callback.run", ...
                "Dispatching callback.");
            testCase.verifyError(@() stream.finish(operation, "completed"), ...
                "labkit:app:contract:InvalidValue");
            stream.close();
            events = stream.records();
            abandoned = events(string({events.eventName}) == "callback.run.abandoned");

            testCase.verifyNumElements(abandoned, 1);
            testCase.verifyEqual(abandoned.operationResult, "abandoned");
            testCase.verifyEqual(abandoned.stateDisposition, "unknown");
            clear cleanup
        end
    end
end

function state = runProbe(state, callbackContext)
callbackContext.log("info", "probe.status", "Semantic status.");
callbackContext.log("debug", "probe.checkpoint", ...
    "Probe checkpoint.", Audience="developer", ...
    Attributes=struct("enum", "checkpoint"));
callbackContext.log("debug", "probe.count", ...
    "Probe count.", Audience="developer", ...
    Attributes=struct("enum", "count", "count", 2));
try
    error("probe:ExpectedFailure", "Expected diagnostic failure.");
catch exception
    callbackContext.log("error", "probe.operation.failed", ...
        "Expected probe failure.", Category="failure", ...
        Audience="developer", Exception=exception);
end
end

function definition = probeDefinition(layout)
definition = labkit.app.Definition( ...
    "Entrypoint", "labkit_LegacyDiagnosticsProbe_app", ...
    "AppId", "probe.legacy-diagnostics", "Title", "Legacy diagnostics probe", ...
    "Family", "Tests", "AppVersion", "1.0.0", "Updated", "2026-07-25", ...
    "Requirements", [], "Workbench", layout);
end
