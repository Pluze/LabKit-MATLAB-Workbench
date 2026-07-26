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
            writeStages = labkitSessionJournalStages( ...
                labkitSessionJournalStages == "open" | ...
                labkitSessionJournalStages == "flush");
            testCase.verifyEqual(writeStages, ...
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

        function coalescesOnlyEquivalentLowSeverityRecords(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            app = journalProbeDefinition();
            journal = labkit.app.internal.SessionJournal(app, ...
                RootFolder=root, SessionId="session-coalescing", BufferRecordLimit=32);
            cleanup = onCleanup(@() journal.close());
            stream = labkit.app.internal.SessionEventStream(app, ...
                SessionId="session-coalescing", ProjectionHook=@journal.append);
            streamCleanup = onCleanup(@() stream.close());

            stream.log("debug", "analysis.repeat", "Repeated diagnostic step.", ...
                Category="app.probe.journal.analysisRun", Audience="developer");
            stream.log("debug", "analysis.repeat", "Repeated diagnostic step.", ...
                Category="app.probe.journal.analysisRun", Audience="developer");
            stream.log("warning", "analysis.degraded", "Analysis degraded.", ...
                Category="app.probe.journal.analysisRun", Audience="user");
            stream.log("warning", "analysis.degraded", "Analysis degraded.", ...
                Category="app.probe.journal.analysisRun", Audience="user");
            manifest = journal.manifest();

            testCase.verifyEqual(manifest.degradation.coalescedRecordCount, 1);
            testCase.verifyEqual(string(manifest.degradation.coalescing.reason), ...
                "repeated-low-severity");
            testCase.verifyEqual(manifest.degradation.coalescing.windowSeconds, 1);
            testCase.verifyEqual(manifest.degradation.droppedRecordCount, 0);
            clear streamCleanup cleanup
        end

        function highFrequencyCoalescingDoesNotWriteManifestPerRecord(testCase)
            global labkitSessionJournalStages
            labkitSessionJournalStages = strings(0, 1);
            resetObserver = onCleanup(@resetJournalObserver);
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            app = journalProbeDefinition();
            journal = labkit.app.internal.SessionJournal(app, ...
                RootFolder=root, SessionId="session-coalescing-manifest", ...
                BufferRecordLimit=128, TestObserver=@recordJournalStage);
            cleanup = onCleanup(@() journal.close());
            stream = labkit.app.internal.SessionEventStream(app, ...
                SessionId="session-coalescing-manifest", ProjectionHook=@journal.append);
            streamCleanup = onCleanup(@() stream.close());

            for index = 1:32
                stream.log("debug", "analysis.repeat", "Repeated diagnostic step.", ...
                    Category="app.probe.journal.analysisRun", Audience="developer");
            end

            manifestStages = labkitSessionJournalStages( ...
                labkitSessionJournalStages == "manifest");
            testCase.verifyNumElements(manifestStages, 1);
            testCase.verifyEqual(journal.manifest().degradation.coalescedRecordCount, 31);
            clear streamCleanup cleanup resetObserver
        end

        function doesNotCoalesceLowSeverityExceptions(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            app = journalProbeDefinition();
            journal = labkit.app.internal.SessionJournal(app, ...
                RootFolder=root, SessionId="session-exception-coalescing", ...
                BufferRecordLimit=32);
            cleanup = onCleanup(@() journal.close());
            stream = labkit.app.internal.SessionEventStream(app, ...
                SessionId="session-exception-coalescing", ProjectionHook=@journal.append);
            streamCleanup = onCleanup(@() stream.close());
            exception = MException("probe:RepeatedFailure", ...
                "Repeated diagnostic failure.");

            stream.log("debug", "analysis.repeat", "Repeated diagnostic step.", ...
                Category="app.probe.journal.analysisRun", Audience="developer", ...
                Exception=exception);
            stream.log("debug", "analysis.repeat", "Repeated diagnostic step.", ...
                Category="app.probe.journal.analysisRun", Audience="developer", ...
                Exception=exception);

            testCase.verifyEqual( ...
                journal.manifest().degradation.coalescedRecordCount, 0);
            clear streamCleanup cleanup
        end

        function preWarningWriteFailureDropsCurrentRecordWithoutFalseCoalescing(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            app = journalProbeDefinition();
            journal = labkit.app.internal.SessionJournal(app, ...
                RootFolder=root, SessionId="session-prewarning-failure", ...
                FaultInjector=@failWrite, BufferRecordLimit=32);
            cleanup = onCleanup(@() journal.close());
            stream = labkit.app.internal.SessionEventStream(app, ...
                SessionId="session-prewarning-failure", ProjectionHook=@journal.append);
            streamCleanup = onCleanup(@() stream.close());

            stream.log("debug", "analysis.repeat", "Repeated diagnostic step.", ...
                Category="app.probe.journal.analysisRun", Audience="developer");
            stream.log("warning", "analysis.degraded", "Analysis degraded.", ...
                Category="app.probe.journal.analysisRun", Audience="user");
            stream.log("debug", "analysis.repeat", "Repeated diagnostic step.", ...
                Category="app.probe.journal.analysisRun", Audience="developer");
            manifest = journal.manifest();

            testCase.verifyEqual(manifest.degradation.coalescedRecordCount, 0);
            testCase.verifyEqual(manifest.degradation.droppedRecordCount, 4);
            testCase.verifyEqual(manifest.degradation.dropReasons.writeFailure, 4);
            clear streamCleanup cleanup
        end

        function inspectionAbandonsOnlyUnprotectedActiveSessions(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            [currentFolder, currentEvents] = writeJournalSession( ...
                root, "session-current", "probe.session-journal");
            markSessionActive(currentFolder);
            [staleFolder, ~] = writeJournalSession( ...
                root, "session-stale", "probe.session-journal");
            markSessionActive(staleFolder);

            snapshot = labkit.app.internal.SessionJournalArchive.snapshot(root, ...
                "session-current");
            exportFolder = fullfile(root, "safe-export");
            labkit.app.internal.SessionJournalArchive.exportSnapshot(root, ...
                "session-current", exportFolder);

            currentManifest = readJson(currentFolder, "manifest.json");
            staleManifest = readJson(staleFolder, "manifest.json");
            testCase.verifyEqual(string(currentManifest.state), "active");
            testCase.verifyTrue(isfile(fullfile(currentFolder, "active.json")));
            testCase.verifyEqual(numel(snapshot.events), numel(currentEvents));
            testCase.verifyEqual(string(snapshot.events(1).eventName), ...
                string(jsondecode(currentEvents(1)).eventName));
            testCase.verifyEqual(string(staleManifest.state), "active");
            testCase.verifyTrue(isfile(fullfile(staleFolder, "active.json")));
            testCase.verifyTrue(isfile(fullfile(exportFolder, "events.jsonl")));
            testCase.verifyTrue(isfile(fullfile(exportFolder, "manifest.json")));
            testCase.verifyTrue(isfile(fullfile(exportFolder, "timeline.txt")));
            testCase.verifyTrue(isfile(fullfile(exportFolder, "degradation.json")));
            redaction = readJson(exportFolder, "redaction.json");
            testCase.verifyEqual(string(redaction.exportProjection), ...
                "canonical-safe-events-only");
            bundleText = join([string(fileread(fullfile(exportFolder, "events.jsonl"))); ...
                string(fileread(fullfile(exportFolder, "timeline.txt")))], newline);
            testCase.verifyFalse(contains(bundleText, string(root)));

            labkit.app.internal.SessionJournalArchive.inspect(root, ...
                ProtectedSessionIds="session-current");
            staleManifest = readJson(staleFolder, "manifest.json");
            testCase.verifyEqual(string(staleManifest.state), "abandoned");
            testCase.verifyFalse(isfile(fullfile(staleFolder, "active.json")));
            testCase.verifyTrue(isfile(fullfile(currentFolder, "active.json")));
        end

        function inspectionPreservesCleanClosedSession(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            folder = writeJournalSession(root, "session-closed", ...
                "probe.session-journal");

            labkit.app.internal.SessionJournalArchive.inspect(root);
            manifest = readJson(folder, "manifest.json");

            testCase.verifyEqual(string(manifest.state), "closed");
            testCase.verifyFalse(isfile(fullfile(folder, "active.json")));
        end

        function recoveryTruncatesOnlyCorruptTailAndReportsMiddleCorruption(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            [folder, expectedEvents] = writeJournalSession( ...
                root, "session-recovery", "probe.session-journal");
            segment = onlySegment(folder);
            appendText(segment, "{");

            inspection = labkit.app.internal.SessionJournalArchive.inspect(root);
            recoveredLines = nonemptyLines(segment);
            snapshot = labkit.app.internal.SessionJournalArchive.snapshot(root, ...
                "session-recovery");

            testCase.verifyEqual(numel(recoveredLines), numel(expectedEvents));
            testCase.verifyEqual(recoveredLines, expectedEvents);
            testCase.verifyEqual(numel(snapshot.events), numel(expectedEvents));
            testCase.verifyEqual(inspection.corruptTailCount, 1);

            appendText(segment, "{invalid-middle}" + newline + ...
                expectedEvents(end));
            snapshot = labkit.app.internal.SessionJournalArchive.snapshot(root, ...
                "session-recovery");

            testCase.verifyEqual(snapshot.degradation.snapshotCorruptRecordCount, 1);
            testCase.verifyEqual(numel(snapshot.events), numel(expectedEvents) + 1);
        end

        function retentionPrunesAgeThenPerAppThenGlobalWithoutCurrentSession(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            ageFolder = writeJournalSession(root, "session-age", "probe.retention-a");
            appOldFolder = writeJournalSession(root, "session-app-old", "probe.retention-a");
            appNewFolder = writeJournalSession(root, "session-app-new", "probe.retention-a");
            otherFolder = writeJournalSession(root, "session-other", "probe.retention-b");
            currentFolder = writeJournalSession(root, "session-current", "probe.retention-b");
            markSessionTimestamp(ageFolder, "closed", utcOffset(-20));
            markSessionTimestamp(appOldFolder, "closed", utcOffset(-3));
            markSessionTimestamp(appNewFolder, "closed", utcOffset(-1));
            markSessionTimestamp(otherFolder, "closed", utcOffset(-2));
            markSessionActive(currentFolder);

            inspection = labkit.app.internal.SessionJournalArchive.inspect(root, ...
                ClosedSessionAgeDays=14, ClosedSessionLimitPerApp=1, ...
                AppByteLimit=1024 * 1024, GlobalByteLimit=1, ...
                ProtectedSessionIds="session-current");

            testCase.verifyFalse(isfolder(ageFolder));
            testCase.verifyFalse(isfolder(appOldFolder));
            testCase.verifyFalse(isfolder(appNewFolder));
            testCase.verifyFalse(isfolder(otherFolder));
            testCase.verifyTrue(isfolder(currentFolder));
            testCase.verifyEqual(inspection.retention.expiredSessionCount, 1);
            testCase.verifyEqual(inspection.retention.perAppPrunedSessionCount, 1);
            testCase.verifyEqual(inspection.retention.globalPrunedSessionCount, 2);
        end

        function retentionReportsProtectedActiveBoundOverflow(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            folder = writeJournalSession(root, "session-current", "probe.retention");
            markSessionActive(folder);

            inspection = labkit.app.internal.SessionJournalArchive.inspect(root, ...
                ProtectedSessionIds="session-current", AppByteLimit=1, ...
                GlobalByteLimit=1);

            testCase.verifyTrue(isfolder(folder));
            testCase.verifyEqual(inspection.retention.unsatisfiedAppIds, ...
                "probe.retention");
            testCase.verifyTrue(inspection.retention.unsatisfiedGlobalByteLimit);
            testCase.verifyGreaterThan(inspection.retention.retainedGlobalBytes, 1);
        end

        function retentionDoesNotMisattributeBoundsAfterAnotherAppPrunes(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            firstFolder = writeJournalSession(root, "session-first", "probe.retention-a");
            secondFolder = writeJournalSession(root, "session-second", "probe.retention-a");
            currentFolder = writeJournalSession(root, "session-current", "probe.retention-b");
            markSessionTimestamp(firstFolder, "closed", utcOffset(-2));
            markSessionTimestamp(secondFolder, "closed", utcOffset(-1));
            markSessionActive(currentFolder);

            inspection = labkit.app.internal.SessionJournalArchive.inspect(root, ...
                ProtectedSessionIds="session-current", ClosedSessionLimitPerApp=1, ...
                AppByteLimit=1, GlobalByteLimit=1024 * 1024);

            testCase.verifyFalse(isfolder(firstFolder));
            testCase.verifyFalse(isfolder(secondFolder));
            testCase.verifyTrue(isfolder(currentFolder));
            testCase.verifyEqual(inspection.retention.unsatisfiedAppIds, ...
                "probe.retention-b");
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

function [folder, events] = writeJournalSession(root, sessionId, appId)
app = journalProbeDefinition(appId);
journal = labkit.app.internal.SessionJournal(app, ...
    RootFolder=root, SessionId=sessionId, BufferRecordLimit=1);
stream = labkit.app.internal.SessionEventStream(app, ...
    SessionId=sessionId, ProjectionHook=@journal.append);
stream.log("info", "analysis.completed", "Analysis completed.", ...
    Category="app.probe.journal.analysisRun", Audience="user");
stream.close();
journal.close();
folder = journal.folder();
events = readCanonicalEvents(folder);
end

function markSessionActive(folder)
manifest = readJson(folder, "manifest.json");
manifest.state = "active";
manifest.closedAtUtc = "";
writeJson(fullfile(folder, "manifest.json"), manifest);
writeJson(fullfile(folder, "active.json"), struct("state", "active"));
end

function markSessionTimestamp(folder, state, timestamp)
manifest = readJson(folder, "manifest.json");
manifest.state = state;
manifest.closedAtUtc = timestamp;
manifest.updatedAtUtc = timestamp;
writeJson(fullfile(folder, "manifest.json"), manifest);
end

function value = utcOffset(dayOffset)
value = string(datetime("now", TimeZone="UTC") + days(dayOffset), ...
    "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
end

function value = readJson(folder, filename)
value = jsondecode(fileread(fullfile(folder, filename)));
end

function writeJson(filepath, value)
file = fopen(filepath, "w", "n", "UTF-8");
cleanup = onCleanup(@() fclose(file));
fprintf(file, "%s", jsonencode(value));
clear cleanup
end

function segment = onlySegment(folder)
segments = dir(fullfile(folder, "events-*.jsonl"));
segment = fullfile(segments(1).folder, segments(1).name);
end

function appendText(filepath, text)
file = fopen(filepath, "a", "n", "UTF-8");
cleanup = onCleanup(@() fclose(file));
fprintf(file, "%s", text);
clear cleanup
end

function lines = nonemptyLines(filepath)
lines = readlines(filepath);
lines = lines(strlength(lines) > 0);
end

function events = readCanonicalEvents(folder)
events = nonemptyLines(onlySegment(folder));
end

function definition = journalProbeDefinition(appId)
if nargin < 1
    appId = "probe.session-journal";
end
definition = labkit.app.Definition( ...
    "Entrypoint", "labkit_SessionJournalProbe_app", ...
    "AppId", appId, "Title", "Session journal probe", ...
    "Family", "Tests", "AppVersion", "1.0.0", "Updated", "2026-07-25", ...
    "Requirements", [], "Workbench", labkit.app.layout.workbench({}));
end
