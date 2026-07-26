classdef SessionLoggingRuntimeSpec < matlab.unittest.TestCase
    %SESSIONLOGGINGRUNTIMESPEC Verify Runtime callback canonical event chains.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function recordsOneCompleteCallbackChain(testCase)
            runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
                runtimeProbeDefinition("run", @runLoggingProbe));
            cleanup = onCleanup(@() runtime.close());

            runtime.invokeAction("run");
            records = runtime.diagnosticEvents();
            started = records(string({records.eventName}) == "callback.pressed.started");
            logged = records(string({records.eventName}) == "analysis.completed");
            completed = records(string({records.eventName}) == "callback.pressed.completed");

            testCase.verifyNumElements(started, 1);
            testCase.verifyNumElements(logged, 1);
            testCase.verifyNumElements(completed, 1);
            testCase.verifyEqual(logged.operationId, started.operationId);
            testCase.verifyEqual(logged.rootActionId, started.rootActionId);
            testCase.verifyEqual(completed.operationId, started.operationId);
            testCase.verifyEqual(completed.outcome, "completed");
            clear cleanup
        end

        function recordsOneRollbackWithoutAFalseCompletedResult(testCase)
            runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
                runtimeProbeDefinition("fail", @failLoggingProbe));
            cleanup = onCleanup(@() runtime.close());

            testCase.verifyError(@() runtime.invokeAction("fail"), ...
                "labkit:app:runtime:ActionFailed");
            records = runtime.diagnosticEvents();
            failed = records(string({records.eventName}) == "callback.pressed.failed");
            completed = records(string({records.eventName}) == "callback.pressed.completed");

            testCase.verifyNumElements(failed, 1);
            testCase.verifyEmpty(completed);
            testCase.verifyEqual(failed.outcome, "failed");
            testCase.verifyEqual(failed.exception.identifier, "probe:ExpectedFailure");
            clear cleanup
        end
    end
end

function state = runLoggingProbe(state, callbackContext)
callbackContext.log("info", "analysis.completed", "Analysis completed.", ...
    Category="analysisRun", Attributes=struct("validItemCount", 2));
end

function state = failLoggingProbe(state, ~)
error("probe:ExpectedFailure", "Expected rollback failure.");
end

function definition = runtimeProbeDefinition(id, callback)
layout = labkit.app.layout.workbench({ ...
    labkit.app.layout.button(id, "Run", callback, Tooltip="Run the probe.")});
definition = labkit.app.Definition( ...
    "Entrypoint", "labkit_SessionLoggingRuntimeProbe_app", ...
    "AppId", "probe.session-logging-runtime", "Title", "Runtime logging probe", ...
    "Family", "Tests", "AppVersion", "1.0.0", "Updated", "2026-07-25", ...
    "Requirements", [], "Workbench", layout);
end
