classdef SessionLoggingRuntimeSpec < matlab.unittest.TestCase
    %SESSIONLOGGINGRUNTIMESPEC Verify Runtime callback canonical event chains.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function defaultFactorySessionIdentityDoesNotChangeRng(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = runtimeProbeDefinition("run", @runLoggingProbe);
            before = rng;
            runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
                definition, [], struct(), labkit.app.diagnostic.Options(), [], ...
                JournalRoot=root);
            cleanup = onCleanup(@() runtime.close());

            testCase.verifyEqual(rng, before);
            clear cleanup
        end

        function rejectsJournalRootAlongsideAnExplicitJournal(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = runtimeProbeDefinition("run", @runLoggingProbe);
            journal = labkit.app.internal.SessionJournal(definition, RootFolder=root);
            cleanup = onCleanup(@() journal.close());

            testCase.verifyError(@() labkit.app.internal.RuntimeFactory.createHeadless( ...
                definition, [], struct(), labkit.app.diagnostic.Options(), journal, ...
                JournalRoot=root), "labkit:app:runtime:InvariantFailure");
            clear cleanup
        end

        function rejectsUnknownJournalOptionsBeforeTheSeamInvariant(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = runtimeProbeDefinition("run", @runLoggingProbe);
            journal = labkit.app.internal.SessionJournal(definition, RootFolder=root);
            cleanup = onCleanup(@() journal.close());

            testCase.verifyError(@() labkit.app.internal.RuntimeFactory.createHeadless( ...
                definition, [], struct(), labkit.app.diagnostic.Options(), journal, ...
                UnknownJournalOption=root), "labkit:app:contract:UnknownArgument");
            clear cleanup
        end

        function recordsOneCompleteCallbackChain(testCase)
            runtime = runtimeWithJournal(testCase, "session-runtime-complete", ...
                "run", @runLoggingProbe);
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
            testCase.verifyEqual(string(completed.outcome), "completed");
            clear cleanup
        end

        function recordsOneRollbackWithoutAFalseCompletedResult(testCase)
            runtime = runtimeWithJournal(testCase, "session-runtime-fail", ...
                "fail", @failLoggingProbe);
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

        function persistsCorrelationCompleteCallbackHistoryOnClose(testCase)
            [runtime, journal, root] = runtimeWithJournal(testCase, ...
                "session-runtime-persisted", "run", @runLoggingProbe);
            cleanup = onCleanup(@() runtime.close());

            runtime.invokeAction("run");
            runtime.close();
            snapshot = labkit.app.internal.SessionJournalArchive.snapshot( ...
                root, journal.sessionId());
            names = string({snapshot.events.eventName});
            started = snapshot.events(names == "callback.pressed.started");
            completed = snapshot.events(names == "callback.pressed.completed");

            testCase.verifyNumElements(started, 1);
            testCase.verifyNumElements(completed, 1);
            testCase.verifyEqual(started.rootActionId, completed.rootActionId);
            testCase.verifyEqual(string(completed.outcome), "completed");
            testCase.verifyEqual(string(snapshot.manifest.state), "closed");
            clear cleanup
        end

        function journalWriteFailureDoesNotChangeCallbackOutcome(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = runtimeProbeDefinition("run", @runLoggingProbe);
            journal = labkit.app.internal.SessionJournal(definition, ...
                RootFolder=root, SessionId="session-runtime-write-failure", ...
                FaultInjector=@failJournalWrite);
            runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
                definition, [], struct(), labkit.app.diagnostic.Options(), journal);
            cleanup = onCleanup(@() runtime.close());

            runtime.invokeAction("run");
            runtime.close();
            records = runtime.diagnosticEvents();
            manifest = journal.manifest();

            testCase.verifyTrue(any(string({records.eventName}) == ...
                "callback.pressed.completed"));
            testCase.verifyEqual(runtime.State.project, struct());
            testCase.verifyEqual(manifest.degradation.writeFailureCount, 1);
            testCase.verifyGreaterThan(manifest.degradation.droppedRecordCount, 0);
            testCase.verifyGreaterThan( ...
                manifest.degradation.dropReasons.writeFailure, 0);
            clear cleanup
        end

        function closesJournalWhenRuntimeConstructionFails(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = runtimeProbeDefinition("run", @runLoggingProbe, ...
                @failRuntimeSession);
            journal = labkit.app.internal.SessionJournal(definition, ...
                RootFolder=root, SessionId="session-runtime-construction-failure");

            testCase.verifyError(@() labkit.app.internal.RuntimeFactory.createHeadless( ...
                definition, [], struct(), labkit.app.diagnostic.Options(), journal), ...
                "probe:SessionConstructionFailure");

            testCase.verifyEqual(string(journal.manifest().state), "closed");
            testCase.verifyFalse(isfile(fullfile(journal.folder(), "active.json")));
        end
    end
end

function [runtime, journal, root] = runtimeWithJournal(testCase, sessionId, id, callback)
root = testCase.applyFixture( ...
    matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
definition = runtimeProbeDefinition(id, callback);
journal = labkit.app.internal.SessionJournal(definition, ...
    RootFolder=root, SessionId=sessionId);
runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
    definition, [], struct(), labkit.app.diagnostic.Options(), journal);
end

function failJournalWrite(stage)
if string(stage) == "write"
    error("labkit:test:JournalWriteFailure", "Intentional writer failure.");
end
end

function state = runLoggingProbe(state, callbackContext)
callbackContext.log("info", "analysis.completed", "Analysis completed.", ...
    Category="analysisRun", Attributes=struct("validItemCount", 2));
end

function state = failLoggingProbe(state, ~)
error("probe:ExpectedFailure", "Expected rollback failure.");
end

function definition = runtimeProbeDefinition(id, callback, createSession)
if nargin < 3
    createSession = [];
end
layout = labkit.app.layout.workbench({ ...
    labkit.app.layout.button(id, "Run", callback, Tooltip="Run the probe.")});
arguments = { ...
    "Entrypoint", "labkit_SessionLoggingRuntimeProbe_app", ...
    "AppId", "probe.session-logging-runtime", "Title", "Runtime logging probe", ...
    "Family", "Tests", "AppVersion", "1.0.0", "Updated", "2026-07-25", ...
    "Requirements", [], "Workbench", layout};
if ~isempty(createSession)
    arguments = [arguments, {"CreateSession", createSession}];
end
definition = labkit.app.Definition(arguments{:});
end

function session = failRuntimeSession(~, ~)
error("probe:SessionConstructionFailure", "Intentional session construction failure.");
end
