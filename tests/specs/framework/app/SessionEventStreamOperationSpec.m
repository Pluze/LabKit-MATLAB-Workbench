classdef SessionEventStreamOperationSpec < matlab.unittest.TestCase
    %SESSIONEVENTSTREAMOPERATIONSPEC Verify private operation state boundaries.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function preservesNestedAncestryAndOneTerminalResult(testCase)
            stream = labkit.app.internal.SessionEventStream(operationProbeDefinition());
            cleanup = onCleanup(@() stream.close());

            outer = stream.begin("runtime.callback", "callback.run", ...
                "Dispatching callback.");
            inner = stream.begin("app.probe", "analysis.run", ...
                "Running analysis.");
            exception = MException("probe:ExpectedFailure", "Expected failure.");
            stream.finish(inner, "failed", "rolledBack", exception);
            stream.finish(outer, "completed", "committed");
            records = stream.records();
            innerStarted = records(string({records.eventName}) == "analysis.run.started");
            innerFailed = records(string({records.eventName}) == "analysis.run.failed");
            outerCompleted = records(string({records.eventName}) == "callback.run.completed");

            testCase.verifyNumElements(innerStarted, 1);
            testCase.verifyNumElements(innerFailed, 1);
            testCase.verifyNumElements(outerCompleted, 1);
            testCase.verifyEqual(innerStarted.parentOperationId, outer.Id);
            testCase.verifyEqual(innerStarted.rootActionId, outer.RootActionId);
            testCase.verifyEqual(innerFailed.operationResult, "failed");
            testCase.verifyEqual(innerFailed.stateDisposition, "rolledBack");
            testCase.verifyEqual(innerFailed.exception.identifier, "probe:ExpectedFailure");
            testCase.verifyEmpty(records(string({records.eventName}) == ...
                "analysis.run.completed"));
            clear cleanup
        end

        function rejectsDoubleUnknownAndOutOfOrderFinishes(testCase)
            stream = labkit.app.internal.SessionEventStream(operationProbeDefinition());
            cleanup = onCleanup(@() stream.close());

            outer = stream.begin("runtime.callback", "callback.run", ...
                "Dispatching callback.");
            inner = stream.begin("app.probe", "analysis.run", ...
                "Running analysis.");
            testCase.verifyError(@() stream.finish(outer, "completed", "committed"), ...
                "labkit:app:runtime:OutOfOrderOperation");
            stream.finish(inner, "completed", "committed");
            testCase.verifyError(@() stream.finish(inner, "completed", "committed"), ...
                "labkit:app:runtime:OperationAlreadyFinished");
            unknown = outer;
            unknown.Id = "op-unknown";
            testCase.verifyError(@() stream.finish(unknown, "completed", "committed"), ...
                "labkit:app:runtime:UnknownOperation");
            stream.finish(outer, "completed", "committed");
            clear cleanup
        end

        function rejectsFinishingAnOperationAfterStreamClose(testCase)
            stream = labkit.app.internal.SessionEventStream(operationProbeDefinition());
            operation = stream.begin("runtime.callback", "callback.run", ...
                "Dispatching callback.");
            stream.close();

            testCase.verifyError(@() stream.finish(operation, "completed", "committed"), ...
                "labkit:app:runtime:OperationClosed");
        end

        function closesActiveOperationsAsAbandonedFromInnerToOuter(testCase)
            stream = labkit.app.internal.SessionEventStream(operationProbeDefinition());
            outer = stream.begin("runtime.callback", "callback.run", ...
                "Dispatching callback.");
            inner = stream.begin("app.probe", "analysis.run", ...
                "Running analysis.");

            stream.close();
            records = stream.records();
            innerAbandoned = records(string({records.eventName}) == "analysis.run.abandoned");
            outerAbandoned = records(string({records.eventName}) == "callback.run.abandoned");
            closed = records(string({records.eventName}) == "session.closed");

            testCase.verifyNumElements(innerAbandoned, 1);
            testCase.verifyNumElements(outerAbandoned, 1);
            testCase.verifyNumElements(closed, 1);
            testCase.verifyEqual(innerAbandoned.parentOperationId, outer.Id);
            testCase.verifyEqual(innerAbandoned.rootActionId, outer.RootActionId);
            testCase.verifyEqual(innerAbandoned.operationResult, "abandoned");
            testCase.verifyEqual(innerAbandoned.stateDisposition, "unknown");
            testCase.verifyEqual(outerAbandoned.operationResult, "abandoned");
            testCase.verifyEqual(outerAbandoned.stateDisposition, "unknown");
            testCase.verifyLessThan(innerAbandoned.sequence, outerAbandoned.sequence);
            testCase.verifyLessThan(outerAbandoned.sequence, closed.sequence);
            testCase.verifyEmpty(records(string({records.eventName}) == ...
                "analysis.run.completed"));
            testCase.verifyEmpty(records(string({records.eventName}) == ...
                "callback.run.completed"));
        end

        function rejectsUnsupportedTerminalOutcomes(testCase)
            stream = labkit.app.internal.SessionEventStream(operationProbeDefinition());
            cleanup = onCleanup(@() stream.close());
            operation = stream.begin("runtime.callback", "callback.run", ...
                "Dispatching callback.");

            testCase.verifyError(@() stream.finish(operation, "completed"), ...
                "labkit:app:contract:InvalidValue");
            testCase.verifyError(@() stream.finish(operation, "banana", "committed"), ...
                "labkit:app:contract:InvalidValue");
            stream.finish(operation, "Completed", "committed");
            rolledBack = stream.begin("runtime.callback", "callback.rollback", ...
                "Rolling back callback.");
            stream.finish(rolledBack, "failed", "rolledBack");
            records = stream.records();
            terminal = records(string({records.eventName}) == ...
                "callback.rollback.failed");
            testCase.verifyNumElements(terminal, 1);
            testCase.verifyEqual(terminal.operationResult, "failed");
            testCase.verifyEqual(terminal.stateDisposition, "rolledBack");
            clear cleanup
        end

        function isolatesAFailingPrivateConsumerAfterRetention(testCase)
            stream = labkit.app.internal.SessionEventStream( ...
                operationProbeDefinition(), ProjectionHook=@throwFromConsumer);
            cleanup = onCleanup(@() stream.close());

            operation = stream.begin("runtime.callback", "callback.run", ...
                "Dispatching callback.");
            stream.finish(operation, "completed", "committed");
            records = stream.records();
            started = records(string({records.eventName}) == "callback.run.started");
            completed = records(string({records.eventName}) == "callback.run.completed");

            testCase.verifyNumElements(started, 1);
            testCase.verifyNumElements(completed, 1);
            testCase.verifyEqual(completed.operationResult, "completed");
            testCase.verifyEqual(completed.stateDisposition, "committed");
            testCase.verifyEqual(completed.operationId, operation.Id);
            clear cleanup
        end
    end
end

function throwFromConsumer(~)
error("labkit:test:ConsumerFailure", "Intentional downstream failure.");
end

function definition = operationProbeDefinition()
definition = labkit.app.Definition( ...
    "Entrypoint", "labkit_SessionEventOperationProbe_app", ...
    "AppId", "probe.session-event-operation", "Title", "Session operation probe", ...
    "Family", "Tests", "AppVersion", "1.0.0", "Updated", "2026-07-25", ...
    "Requirements", [], "Workbench", labkit.app.layout.workbench({}));
end
