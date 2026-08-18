classdef SessionJournalSpec < matlab.unittest.TestCase
    %SESSIONJOURNALSPEC Verify the private buffered canonical session store.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function rejectsLegacyScalarOutcomeRecords(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            app = journalProbeDefinition();
            journal = labkit.app.internal.diagnostics.SessionJournal(app, ...
                RootFolder=root, SessionId="session-old-schema");
            cleanup = onCleanup(@() journal.close());
            stream = labkit.app.internal.diagnostics.SessionEventStream(app, ...
                SessionId="session-old-schema");
            streamCleanup = onCleanup(@() stream.close());
            legacy = stream.records();
            legacy = legacy(end);
            legacy = rmfield(legacy, {'operationResult', 'stateDisposition'});
            legacy.outcome = "completed";

            journal.append(legacy);
            health = journal.healthSnapshot();

            testCase.verifyEqual( ...
                journal.manifest().degradation.dropReasons.invalidCanonicalRecord, 1);
            testCase.verifyEqual(string(fieldnames(health)), [ ...
                "state"; "available"; "droppedRecordCount"; ...
                "invalidCanonicalRecordDropCount"; "writeFailureDropCount"; ...
                "writeFailureCount"; "lastFailureReason"; "degradationReason"]);
            testCase.verifyEqual(health.state, "healthy");
            testCase.verifyTrue(health.available);
            testCase.verifyEqual(health.droppedRecordCount, 1);
            testCase.verifyEqual(health.invalidCanonicalRecordDropCount, 1);
            testCase.verifyEqual(health.writeFailureDropCount, 0);
            clear streamCleanup cleanup
        end

        function archiveRejectsLegacyScalarOutcomeJsonlRecords(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            [folder, expectedEvents] = writeJournalSession( ...
                root, "session-old-archive-schema", "probe.session-journal");
            record = jsondecode(expectedEvents(1));
            legacy = rmfield(record, {'operationResult', 'stateDisposition'});
            legacy.outcome = "completed";
            legacyFields = ["schemaVersion", "sequence", "timestampUtc", ...
                "elapsedSeconds", "severity", "audience", "category", ...
                "eventName", "message", "attributes", "sessionId", "appId", ...
                "operationId", "parentOperationId", "rootActionId", "outcome", ...
                "durationSeconds", "exception"];
            legacy = orderfields(legacy, cellstr(legacyFields));
            appendText(onlySegment(folder), string(jsonencode(legacy)) + newline);

            snapshot = labkit.app.internal.diagnostics.SessionJournalArchive.snapshot( ...
                root, "session-old-archive-schema");

            testCase.verifyEqual(numel(snapshot.events), numel(expectedEvents));
            testCase.verifyEqual(snapshot.degradation.snapshotCorruptRecordCount, 1);
        end

        function rejectsMismatchedTerminalPairsInJournalAndArchive(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            app = journalProbeDefinition();
            journal = labkit.app.internal.diagnostics.SessionJournal(app, ...
                RootFolder=root, SessionId="session-mismatched-pair");
            cleanup = onCleanup(@() journal.close());
            stream = labkit.app.internal.diagnostics.SessionEventStream(app, ...
                SessionId="session-mismatched-pair");
            streamCleanup = onCleanup(@() stream.close());
            mismatch = stream.records();
            mismatch = mismatch(end);
            mismatch.operationResult = "failed";
            mismatch.stateDisposition = "committed";
            journal.append(mismatch);

            testCase.verifyEqual( ...
                journal.manifest().degradation.dropReasons.invalidCanonicalRecord, 1);
            clear streamCleanup cleanup

            [folder, expectedEvents] = writeJournalSession( ...
                root, "session-mismatched-archive", "probe.session-journal");
            mismatch = jsondecode(expectedEvents(1));
            mismatch.operationResult = "failed";
            mismatch.stateDisposition = "committed";
            appendText(onlySegment(folder), string(jsonencode(mismatch)) + newline);
            snapshot = labkit.app.internal.diagnostics.SessionJournalArchive.snapshot( ...
                root, "session-mismatched-archive");

            testCase.verifyEqual(numel(snapshot.events), numel(expectedEvents));
            testCase.verifyEqual(snapshot.degradation.snapshotCorruptRecordCount, 1);
        end

        function defaultSessionIdentityDoesNotChangeRng(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            app = journalProbeDefinition();
            before = rng;
            journal = labkit.app.internal.diagnostics.SessionJournal(app, RootFolder=root);
            cleanup = onCleanup(@() journal.close());

            testCase.verifyEqual(rng, before);
            clear cleanup
        end

        function defaultRootFolderUsesInstallationArtifacts(testCase)
            versionPath = string(which("labkit.app.version"));
            installationRoot = string(fileparts(fileparts(fileparts(versionPath))));

            folder = ...
                labkit.app.internal.diagnostics.SessionJournal.defaultRootFolder();

            testCase.verifyEqual(folder, ...
                fullfile(installationRoot, "artifacts", "logs"));
        end

        function buffersContextAndFlushesAroundWarnings(testCase)
            testfixtures.StateStore.set("journalStages", strings(0, 1));
            resetObserver = onCleanup(@resetJournalObserver);
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            app = journalProbeDefinition();
            journal = labkit.app.internal.diagnostics.SessionJournal(app, ...
                RootFolder=root, SessionId="session-buffer", ...
                BufferRecordLimit=32, TestObserver=@recordJournalStage);
            cleanup = onCleanup(@() journal.close());
            stream = labkit.app.internal.diagnostics.SessionEventStream(app, ...
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
            stages = testfixtures.StateStore.get("journalStages");
            writeStages = stages(stages == "open" | stages == "flush");
            testCase.verifyEqual(writeStages, ...
                ["open", "flush", "flush"]);
            clear streamCleanup cleanup resetObserver
        end

        function countsWarningDroppedAfterPreflushManifestFailure(testCase)
            testfixtures.StateStore.set("preflushManifestFaultCount", 0);
            resetFault = onCleanup(@resetPreflushManifestFault);
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            app = journalProbeDefinition();
            journal = labkit.app.internal.diagnostics.SessionJournal(app, ...
                RootFolder=root, SessionId="session-warning-manifest-failure", ...
                BufferRecordLimit=32, FaultInjector=@failPreflushManifest);
            cleanup = onCleanup(@() journal.close());
            projection = labkit.app.internal.diagnostics.SessionJournalProjection(journal);
            stream = labkit.app.internal.diagnostics.SessionEventStream(app, ...
                SessionId="session-warning-manifest-failure", ...
                ProjectionHook=@projection.project, ...
                ProjectionHealthHook=@projection.drainHealth);
            streamCleanup = onCleanup(@() stream.close());

            stream.log("debug", "analysis.context", "Context retained.", ...
                Category="app.probe.journal.analysisRun", Audience="developer");
            stream.log("warning", "analysis.warning", "Warning retained.", ...
                Category="app.probe.journal.analysisRun", Audience="developer");
            snapshot = journal.healthSnapshot();
            records = stream.records();
            names = string({records.eventName});
            dropped = records(names == "journal.records_dropped");
            stream.refreshProjectionHealth();
            refreshed = stream.records();
            persisted = readCanonicalEvents(journal.folder());

            testCase.verifyEqual(snapshot.droppedRecordCount, 1);
            testCase.verifyEqual(snapshot.writeFailureDropCount, 1);
            testCase.verifyEqual(numel(dropped), 1);
            testCase.verifyEqual(dropped.attributes.reason, "write-failure");
            testCase.verifyEqual(dropped.attributes.count, 1);
            testCase.verifyNumElements(refreshed( ...
                string({refreshed.eventName}) == "journal.records_dropped"), 1);
            testCase.verifyTrue(any(contains(persisted, '"eventName":"analysis.context"')));
            testCase.verifyFalse(any(contains(persisted, '"eventName":"analysis.warning"')));
            clear streamCleanup cleanup resetFault
        end

        function serializesExactlyTheCanonicalRecordFields(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            app = journalProbeDefinition();
            journal = labkit.app.internal.diagnostics.SessionJournal(app, ...
                RootFolder=root, SessionId="session-schema", BufferRecordLimit=1);
            cleanup = onCleanup(@() journal.close());
            stream = labkit.app.internal.diagnostics.SessionEventStream(app, ...
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
                "rootActionId"; "operationResult"; "stateDisposition"; ...
                "durationSeconds"; "exception"]);
            testCase.verifyEqual(string(stored.eventName), "analysis.completed");
            clear streamCleanup cleanup
        end

        function recordsActiveSessionStateUntilAnOrderlyClose(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            app = journalProbeDefinition();
            journal = labkit.app.internal.diagnostics.SessionJournal(app, ...
                RootFolder=root, SessionId="session-state");
            journalFolder = journal.folder();

            testCase.verifyEqual(string(journal.manifest().state), "active");
            manifest = journal.manifest();
            startedAtUtc = datetime(manifest.startedAtUtc, ...
                InputFormat="yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", TimeZone="UTC");
            testCase.verifyFalse(isnat(startedAtUtc));
            journal.close();

            testCase.verifyEqual(string(journal.manifest().state), "closed");
        end

        function boundsRetainedSessionSegmentsWithVisibleDegradation(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            app = journalProbeDefinition();
            journal = labkit.app.internal.diagnostics.SessionJournal(app, ...
                RootFolder=root, SessionId="session-retention", ...
                SegmentByteLimit=256, SegmentLimit=2, SessionByteLimit=1024, ...
                BufferRecordLimit=1);
            cleanup = onCleanup(@() journal.close());
            stream = labkit.app.internal.diagnostics.SessionEventStream(app, ...
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
            journal = labkit.app.internal.diagnostics.SessionJournal(app, ...
                RootFolder=root, SessionId="session-failure", ...
                FaultInjector=@failWrite, BufferRecordLimit=32);
            cleanup = onCleanup(@() journal.close());
            stream = labkit.app.internal.diagnostics.SessionEventStream(app, ...
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
            journal = labkit.app.internal.diagnostics.SessionJournal(app, ...
                RootFolder=root, SessionId="session-coalescing", BufferRecordLimit=32);
            cleanup = onCleanup(@() journal.close());
            stream = labkit.app.internal.diagnostics.SessionEventStream(app, ...
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
            testfixtures.StateStore.set("journalStages", strings(0, 1));
            resetObserver = onCleanup(@resetJournalObserver);
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            app = journalProbeDefinition();
            journal = labkit.app.internal.diagnostics.SessionJournal(app, ...
                RootFolder=root, SessionId="session-coalescing-manifest", ...
                BufferRecordLimit=128, TestObserver=@recordJournalStage);
            cleanup = onCleanup(@() journal.close());
            stream = labkit.app.internal.diagnostics.SessionEventStream(app, ...
                SessionId="session-coalescing-manifest", ProjectionHook=@journal.append);
            streamCleanup = onCleanup(@() stream.close());

            for index = 1:32
                stream.log("debug", "analysis.repeat", "Repeated diagnostic step.", ...
                    Category="app.probe.journal.analysisRun", Audience="developer");
            end

            stages = testfixtures.StateStore.get("journalStages");
            manifestStages = stages(stages == "manifest");
            testCase.verifyNumElements(manifestStages, 1);
            testCase.verifyEqual(journal.manifest().degradation.coalescedRecordCount, 31);
            clear streamCleanup cleanup resetObserver
        end

        function doesNotCoalesceLowSeverityExceptions(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            app = journalProbeDefinition();
            journal = labkit.app.internal.diagnostics.SessionJournal(app, ...
                RootFolder=root, SessionId="session-exception-coalescing", ...
                BufferRecordLimit=32);
            cleanup = onCleanup(@() journal.close());
            stream = labkit.app.internal.diagnostics.SessionEventStream(app, ...
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
            journal = labkit.app.internal.diagnostics.SessionJournal(app, ...
                RootFolder=root, SessionId="session-prewarning-failure", ...
                FaultInjector=@failWrite, BufferRecordLimit=32);
            cleanup = onCleanup(@() journal.close());
            stream = labkit.app.internal.diagnostics.SessionEventStream(app, ...
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

        function snapshotAndExportDoNotMutateRetainedSession(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            [folder, expectedEvents] = writeJournalSession( ...
                root, "session-current", "probe.session-journal");

            snapshot = labkit.app.internal.diagnostics.SessionJournalArchive.snapshot( ...
                root, "session-current");
            exportFolder = fullfile(root, "safe-export");
            labkit.app.internal.diagnostics.SessionJournalArchive.exportSnapshot( ...
                root, "session-current", exportFolder);

            manifest = readJson(folder, "manifest.json");
            testCase.verifyEqual(string(manifest.state), "closed");
            testCase.verifyEqual(numel(snapshot.events), numel(expectedEvents));
            testCase.verifyEqual(string(snapshot.events(1).eventName), ...
                string(jsondecode(expectedEvents(1)).eventName));
            testCase.verifyTrue(isfile(fullfile(exportFolder, "events.jsonl")));
            testCase.verifyTrue(isfile(fullfile(exportFolder, "manifest.json")));
            testCase.verifyTrue(isfile(fullfile(exportFolder, "timeline.txt")));
            testCase.verifyTrue(isfile(fullfile(exportFolder, "degradation.json")));
            redaction = readJson(exportFolder, "redaction.json");
            testCase.verifyEqual(string(redaction.exportProjection), "none");
            bundleText = join([ ...
                string(fileread(fullfile(exportFolder, "events.jsonl"))); ...
                string(fileread(fullfile(exportFolder, "timeline.txt")))], newline);
            testCase.verifyFalse(contains(bundleText, string(root)));
        end
    end
end

function recordJournalStage(stage, ~)
stages = testfixtures.StateStore.get("journalStages", strings(0, 1));
testfixtures.StateStore.set("journalStages", ...
    [reshape(stages, 1, []), string(stage)]);
end

function resetJournalObserver()
testfixtures.StateStore.reset("journalStages");
end

function failWrite(stage)
if string(stage) == "write"
    error("labkit:test:JournalWriteFailure", "Intentional journal write failure.");
end
end

function failPreflushManifest(stage)
if string(stage) ~= "manifest"
    return;
end
count = testfixtures.StateStore.get("preflushManifestFaultCount", 0) + 1;
testfixtures.StateStore.set("preflushManifestFaultCount", count);
if count >= 2
    error("labkit:test:JournalManifestFailure", "Intentional preflush manifest failure.");
end
end

function resetPreflushManifestFault()
testfixtures.StateStore.reset("preflushManifestFaultCount");
end

function [folder, events] = writeJournalSession(root, sessionId, appId)
app = journalProbeDefinition(appId);
journal = labkit.app.internal.diagnostics.SessionJournal(app, ...
    RootFolder=root, SessionId=sessionId, BufferRecordLimit=1);
stream = labkit.app.internal.diagnostics.SessionEventStream(app, ...
    SessionId=sessionId, ProjectionHook=@journal.append);
stream.log("info", "analysis.completed", "Analysis completed.", ...
    Category="app.probe.journal.analysisRun", Audience="user");
stream.close();
journal.close();
folder = journal.folder();
events = readCanonicalEvents(folder);
end

function value = readJson(folder, filename)
value = jsondecode(fileread(fullfile(folder, filename)));
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
