classdef SessionJournalSpec < matlab.unittest.TestCase
    %SESSIONJOURNALSPEC Verify the private buffered canonical session store.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function buffersContextAndFlushesAroundWarnings(testCase)
            global labkitSessionJournalStages
            labkitSessionJournalStages = strings(0, 1);
            resetObserver = onCleanup(@resetJournalObserver);
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            app = journalProbeDefinition();
            journal = labkit.app.internal.SessionJournal(app, ...
                RootFolder=root, SessionId="session-buffer", ...
                BufferRecordLimit=32, TestObserver=@recordJournalStage);
            cleanup = onCleanup(@() journal.close());
            stream = labkit.app.internal.SessionEventStream(app, ...
                SessionId="session-buffer", ProjectionHook=@journal.append);
            streamCleanup = onCleanup(@() stream.close());
            journalFolder = journal.folder();

            stream.log("debug", "analysis.context", "Context retained.", ...
                Category="app.probe.journal.analysisRun", Audience="developer");
            testCase.verifyEmpty(dir(fullfile(journalFolder, "events-*.jsonl")));
            stream.log("warning", "analysis.degraded", "Analysis degraded.", ...
                Category="app.probe.journal.analysisRun", Audience="user");
            segments = dir(fullfile(journalFolder, "events-*.jsonl"));
            lines = readlines(fullfile(segments(1).folder, segments(1).name));
            lines = lines(strlength(lines) > 0);

            testCase.verifyEqual(numel(lines), 3);
            testCase.verifyEqual(labkitSessionJournalStages, ...
                ["open", "flush", "flush"]);
            clear streamCleanup cleanup resetObserver
        end

        function serializesExactlyTheCanonicalRecordFields(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            app = journalProbeDefinition();
            journal = labkit.app.internal.SessionJournal(app, ...
                RootFolder=root, SessionId="session-schema", BufferRecordLimit=1);
            cleanup = onCleanup(@() journal.close());
            stream = labkit.app.internal.SessionEventStream(app, ...
                SessionId="session-schema", ProjectionHook=@journal.append);
            streamCleanup = onCleanup(@() stream.close());
            stream.log("info", "analysis.completed", "Analysis completed.", ...
                Category="app.probe.journal.analysisRun", Audience="user", ...
                Attributes=struct("validItemCount", 2));
            segments = dir(fullfile(journal.folder(), "events-*.jsonl"));
            lines = readlines(fullfile(segments(1).folder, segments(1).name));
            lines = lines(strlength(lines) > 0);
            stored = jsondecode(lines(end));

            testCase.verifyEqual(string(fieldnames(stored)), [ ...
                "schemaVersion"; "sequence"; "timestampUtc"; ...
                "elapsedSeconds"; "severity"; "audience"; "category"; ...
                "eventName"; "message"; "attributes"; "sessionId"; ...
                "appId"; "operationId"; "parentOperationId"; ...
                "rootActionId"; "outcome"; "durationSeconds"; "exception"]);
            testCase.verifyEqual(string(stored.eventName), "analysis.completed");
            clear streamCleanup cleanup
        end

        function recordsActiveSessionStateUntilAnOrderlyClose(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            app = journalProbeDefinition();
            journal = labkit.app.internal.SessionJournal(app, ...
                RootFolder=root, SessionId="session-state");
            journalFolder = journal.folder();

            testCase.verifyTrue(isfile(fullfile(journalFolder, "active.json")));
            testCase.verifyEqual(string(journal.manifest().state), "active");
            journal.close();

            testCase.verifyFalse(isfile(fullfile(journalFolder, "active.json")));
            testCase.verifyEqual(string(journal.manifest().state), "closed");
        end

        function boundsRetainedSessionSegmentsWithVisibleDegradation(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            app = journalProbeDefinition();
            journal = labkit.app.internal.SessionJournal(app, ...
                RootFolder=root, SessionId="session-retention", ...
                SegmentByteLimit=256, SegmentLimit=2, SessionByteLimit=1024, ...
                BufferRecordLimit=1);
            cleanup = onCleanup(@() journal.close());
            stream = labkit.app.internal.SessionEventStream(app, ...
                SessionId="session-retention", ProjectionHook=@journal.append);
            streamCleanup = onCleanup(@() stream.close());

            for index = 1:5
                stream.log("info", "analysis.step", "Analysis step recorded.", ...
                    Category="app.probe.journal.analysisRun", Audience="developer", ...
                    Attributes=struct("ordinal", index));
            end
            segments = dir(fullfile(journal.folder(), "events-*.jsonl"));
            manifest = journal.manifest();

            testCase.verifyLessThanOrEqual(numel(segments), 2);
            testCase.verifyGreaterThan(manifest.degradation.expiredSegmentCount, 0);
            testCase.verifyLessThanOrEqual(manifest.retainedBytes, 1024);
            clear streamCleanup cleanup
        end

        function isolatesWriterFailureFromTheCanonicalCallerOutcome(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            app = journalProbeDefinition();
            journal = labkit.app.internal.SessionJournal(app, ...
                RootFolder=root, SessionId="session-failure", ...
                FaultInjector=@failWrite, BufferRecordLimit=32);
            cleanup = onCleanup(@() journal.close());
            stream = labkit.app.internal.SessionEventStream(app, ...
                SessionId="session-failure", ProjectionHook=@journal.append);
            streamCleanup = onCleanup(@() stream.close());
            scientificOutcome = "completed";

            stream.log("warning", "analysis.degraded", "Analysis degraded.", ...
                Category="app.probe.journal.analysisRun", Audience="user");
            manifest = journal.manifest();

            testCase.verifyEqual(scientificOutcome, "completed");
            testCase.verifyEqual(numel(stream.records()), 2);
            testCase.verifyEqual(manifest.degradation.writeFailureCount, 1);
            clear streamCleanup cleanup
        end
    end
end

function recordJournalStage(stage, ~)
global labkitSessionJournalStages
labkitSessionJournalStages(end + 1) = string(stage);
end

function resetJournalObserver()
global labkitSessionJournalStages
labkitSessionJournalStages = strings(0, 1);
end

function failWrite(stage)
if string(stage) == "write"
    error("labkit:test:JournalWriteFailure", "Intentional journal write failure.");
end
end

function definition = journalProbeDefinition()
definition = labkit.app.Definition( ...
    "Entrypoint", "labkit_SessionJournalProbe_app", ...
    "AppId", "probe.session-journal", "Title", "Session journal probe", ...
    "Family", "Tests", "AppVersion", "1.0.0", "Updated", "2026-07-25", ...
    "Requirements", [], "Workbench", labkit.app.layout.workbench({}));
end
