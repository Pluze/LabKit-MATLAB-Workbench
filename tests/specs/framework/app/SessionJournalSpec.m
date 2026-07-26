classdef SessionJournalSpec < matlab.unittest.TestCase
    %SESSIONJOURNALSPEC Verify the private buffered canonical session store.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function rejectsLegacyScalarOutcomeRecords(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            app = journalProbeDefinition();
            journal = labkit.app.internal.SessionJournal(app, ...
                RootFolder=root, SessionId="session-old-schema");
            cleanup = onCleanup(@() journal.close());
            stream = labkit.app.internal.SessionEventStream(app, ...
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

            snapshot = labkit.app.internal.SessionJournalArchive.snapshot( ...
                root, "session-old-archive-schema");

            testCase.verifyEqual(numel(snapshot.events), numel(expectedEvents));
            testCase.verifyEqual(snapshot.degradation.snapshotCorruptRecordCount, 1);
        end

        function rejectsMismatchedTerminalPairsInJournalAndArchive(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            app = journalProbeDefinition();
            journal = labkit.app.internal.SessionJournal(app, ...
                RootFolder=root, SessionId="session-mismatched-pair");
            cleanup = onCleanup(@() journal.close());
            stream = labkit.app.internal.SessionEventStream(app, ...
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
            snapshot = labkit.app.internal.SessionJournalArchive.snapshot( ...
                root, "session-mismatched-archive");

            testCase.verifyEqual(numel(snapshot.events), numel(expectedEvents));
            testCase.verifyEqual(snapshot.degradation.snapshotCorruptRecordCount, 1);
        end

        function defaultSessionIdentityDoesNotChangeRng(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            app = journalProbeDefinition();
            before = rng;
            journal = labkit.app.internal.SessionJournal(app, RootFolder=root);
            cleanup = onCleanup(@() journal.close());

            testCase.verifyEqual(rng, before);
            clear cleanup
        end

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

        function countsWarningDroppedAfterPreflushManifestFailure(testCase)
            global labkitPreflushManifestFaultCount
            labkitPreflushManifestFaultCount = 0;
            resetFault = onCleanup(@resetPreflushManifestFault);
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            app = journalProbeDefinition();
            journal = labkit.app.internal.SessionJournal(app, ...
                RootFolder=root, SessionId="session-warning-manifest-failure", ...
                BufferRecordLimit=32, FaultInjector=@failPreflushManifest);
            cleanup = onCleanup(@() journal.close());
            projection = labkit.app.internal.SessionJournalProjection(journal);
            stream = labkit.app.internal.SessionEventStream(app, ...
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
                "rootActionId"; "operationResult"; "stateDisposition"; ...
                "durationSeconds"; "exception"]);
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
            marker = readJson(journalFolder, "active.json");
            manifest = journal.manifest();
            testCase.verifyEqual(string(fieldnames(marker)), [ ...
                "sessionId"; "appId"; "state"; "host"; "pid"; "nonce"; ...
                "startedAtUtc"; "heartbeatAtUtc"; "leaseVersion"]);
            testCase.verifyEqual(string(marker.sessionId), "session-state");
            testCase.verifyEqual(string(marker.appId), string(app.AppId));
            testCase.verifyEqual(string(marker.state), "active");
            testCase.verifyTrue(isstring(string(marker.host)) && isscalar(string(marker.host)) && ...
                strlength(string(marker.host)) > 0);
            testCase.verifyTrue(isnumeric(marker.pid) && isscalar(marker.pid) && ...
                isfinite(marker.pid) && marker.pid == fix(marker.pid) && marker.pid >= -1);
            testCase.verifyGreaterThan(strlength(string(marker.nonce)), 0);
            startedAtUtc = datetime(marker.startedAtUtc, ...
                InputFormat="yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", TimeZone="UTC");
            heartbeatAtUtc = datetime(marker.heartbeatAtUtc, ...
                InputFormat="yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", TimeZone="UTC");
            testCase.verifyFalse(isnat(startedAtUtc));
            testCase.verifyFalse(isnat(heartbeatAtUtc));
            testCase.verifyEqual(marker.leaseVersion, 1);
            testCase.verifyEqual(string(manifest.lease.nonce), string(marker.nonce));
            testCase.verifyEqual(manifest.lease.leaseVersion, marker.leaseVersion);
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

        function inspectionOnlyAbandonsConfirmedStaleSessions(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            [currentFolder, currentEvents] = writeJournalSession( ...
                root, "session-current", "probe.session-journal");
            nowUtc = "2030-01-01T00:10:00.000Z";
            markSessionActive(currentFolder, "2030-01-01T00:00:00.000Z", ...
                "nonce-current", 41);
            [staleFolder, ~] = writeJournalSession( ...
                root, "session-stale", "probe.session-journal");
            markSessionActive(staleFolder, "2030-01-01T00:00:00.000Z", ...
                "nonce-stale", 42);

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
                ProtectedSessionIds="session-current", LeaseClock=@() nowUtc, ...
                LeaseProbe=@deadLeaseProbe);
            staleManifest = readJson(staleFolder, "manifest.json");
            testCase.verifyEqual(string(staleManifest.state), "abandoned");
            testCase.verifyFalse(isfile(fullfile(staleFolder, "active.json")));
            testCase.verifyTrue(isfile(fullfile(currentFolder, "active.json")));
        end

        function classifiesLeaseOwnershipConservativelyAndNeverThrows(testCase)
            startedAtUtc = "2030-01-01T00:00:00.000Z";
            marker = labkit.app.internal.SessionLease.create( ...
                "session-lease", "probe.session-journal", startedAtUtc, ...
                startedAtUtc, "nonce-lease", leaseOwnerProbe());
            manifest = activeLeaseManifest(marker);
            freshProbe = leaseProcessProbe(41, "alive");

            testCase.verifyEqual(labkit.app.internal.SessionLease.classify( ...
                marker, manifest, "2030-01-01T00:00:10.000Z", freshProbe, 60), "live");
            testCase.verifyEqual(labkit.app.internal.SessionLease.classify( ...
                marker, manifest, "2030-01-01T00:02:00.000Z", ...
                leaseProcessProbe(41, "dead"), 60), "stale");
            testCase.verifyEqual(labkit.app.internal.SessionLease.classify( ...
                marker, manifest, "2030-01-01T00:02:00.000Z", freshProbe, 60), "uncertain");
            wrongTargetProbe = leaseProcessProbe(99, "dead");
            testCase.verifyEqual(labkit.app.internal.SessionLease.classify( ...
                marker, manifest, "2030-01-01T00:02:00.000Z", wrongTargetProbe, 60), "uncertain");
            testCase.verifyEqual(labkit.app.internal.SessionLease.classify( ...
                marker, manifest, "2030-01-01T00:00:10.000Z", ...
                remoteLeaseProbe(41, "dead"), 60), "live");
            testCase.verifyEqual(labkit.app.internal.SessionLease.classify( ...
                marker, manifest, "2030-01-01T00:02:00.000Z", ...
                remoteLeaseProbe(41, "dead"), 60), "uncertain");

            nonceMismatch = manifest;
            nonceMismatch.lease.nonce = "different-nonce";
            futureMarker = marker;
            futureMarker.heartbeatAtUtc = "2030-01-01T00:03:00.000Z";
            malformed = marker;
            malformed.host = ["fixture-host", "other-host"];
            testCase.verifyEqual(labkit.app.internal.SessionLease.classify( ...
                struct(), manifest, "2030-01-01T00:02:00.000Z", freshProbe, 60), "uncertain");
            testCase.verifyEqual(labkit.app.internal.SessionLease.classify( ...
                marker, nonceMismatch, "2030-01-01T00:02:00.000Z", freshProbe, 60), "uncertain");
            testCase.verifyEqual(labkit.app.internal.SessionLease.classify( ...
                futureMarker, manifest, "2030-01-01T00:02:00.000Z", freshProbe, 60), "uncertain");
            testCase.verifyEqual(labkit.app.internal.SessionLease.classify( ...
                malformed, manifest, "2030-01-01T00:02:00.000Z", freshProbe, 60), "uncertain");
        end

        function inspectionReportsLiveUncertainAndStaleLeaseCounts(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            liveFolder = writeJournalSession(root, "session-live", "probe.session-journal");
            staleFolder = writeJournalSession(root, "session-stale", "probe.session-journal");
            uncertainFolder = writeJournalSession(root, "session-uncertain", "probe.session-journal");
            markSessionActive(liveFolder, "2030-01-01T00:09:30.000Z", "nonce-live", 41);
            markSessionActive(staleFolder, "2030-01-01T00:00:00.000Z", "nonce-stale", 42);
            markSessionActive(uncertainFolder, "2030-01-01T00:00:00.000Z", "nonce-uncertain", 43);

            inspection = labkit.app.internal.SessionJournalArchive.inspect(root, ...
                LeaseClock=@() "2030-01-01T00:10:00.000Z", ...
                LeaseProbe=@mixedLeaseProbe);

            testCase.verifyEqual(inspection.liveSessionCount, 1);
            testCase.verifyEqual(inspection.uncertainSessionCount, 1);
            testCase.verifyEqual(inspection.staleSessionCount, 1);
            testCase.verifyEqual(string(readJson(staleFolder, "manifest.json").state), "abandoned");
            testCase.verifyEqual(string(readJson(liveFolder, "manifest.json").state), "active");
            testCase.verifyEqual(string(readJson(uncertainFolder, "manifest.json").state), "active");
        end

        function inspectionTreatsMalformedMarkerFieldsAsUncertainWithoutMutation(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            folder = writeJournalSession(root, "session-malformed-marker", ...
                "probe.session-journal");
            markSessionActive(folder, "2030-01-01T00:00:00.000Z", ...
                "nonce-malformed", 41);
            marker = readJson(folder, "active.json");
            marker.host = {"fixture-host", "other-host"};
            writeJson(fullfile(folder, "active.json"), marker);

            inspection = labkit.app.internal.SessionJournalArchive.inspect(root, ...
                LeaseClock=@() "2030-01-01T00:10:00.000Z", ...
                LeaseProbe=@deadLeaseProbe);

            testCase.verifyEqual(inspection.uncertainSessionCount, 1);
            testCase.verifyEqual(inspection.recoveredSessionCount, 0);
            testCase.verifyTrue(isfile(fullfile(folder, "active.json")));
            testCase.verifyEqual(string(readJson(folder, "manifest.json").state), "active");
        end

        function heartbeatsOnlyAfterTheConfiguredFlushInterval(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            resetLeaseClock(["2030-01-01T00:00:00.000Z"; ...
                "2030-01-01T00:00:00.000Z"; "2030-01-01T00:00:05.000Z"; ...
                "2030-01-01T00:00:31.000Z"; "2030-01-01T00:00:31.000Z"]);
            clockCleanup = onCleanup(@resetLeaseClock);
            app = journalProbeDefinition();
            journal = labkit.app.internal.SessionJournal(app, RootFolder=root, ...
                SessionId="session-heartbeat", LeaseClock=@nextLeaseClock, ...
                LeaseProbe=@() leaseOwnerProbe(), HeartbeatIntervalSeconds=30);
            cleanup = onCleanup(@() journal.close());
            stream = labkit.app.internal.SessionEventStream(app, SessionId="session-heartbeat");
            streamCleanup = onCleanup(@() stream.close());
            record = stream.records();

            journal.append(record(end));
            journal.flush();
            withinInterval = readJson(journal.folder(), "active.json");
            journal.append(record(end));
            journal.flush();
            afterInterval = readJson(journal.folder(), "active.json");

            testCase.verifyEqual(string(journal.manifest().startedAtUtc), ...
                "2030-01-01T00:00:00.000Z");
            testCase.verifyEqual(string(withinInterval.heartbeatAtUtc), ...
                "2030-01-01T00:00:00.000Z");
            testCase.verifyEqual(string(afterInterval.heartbeatAtUtc), ...
                "2030-01-01T00:00:31.000Z");
            clear streamCleanup cleanup clockCleanup
        end

        function retentionNeverPrunesLiveOrUncertainSessionsUnderZeroLimits(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            liveFolder = writeJournalSession(root, "session-live-bound", "probe.retention-live");
            uncertainFolder = writeJournalSession(root, "session-uncertain-bound", "probe.retention-uncertain");
            markSessionActive(liveFolder, "2030-01-01T00:09:30.000Z", "nonce-live-bound", 41);
            markSessionActive(uncertainFolder, "2030-01-01T00:00:00.000Z", ...
                "nonce-uncertain-bound", 43);

            inspection = labkit.app.internal.SessionJournalArchive.inspect(root, ...
                ClosedSessionLimitPerApp=0, AppByteLimit=0, GlobalByteLimit=0, ...
                LeaseClock=@() "2030-01-01T00:10:00.000Z", ...
                LeaseProbe=@mixedLeaseProbe);

            testCase.verifyTrue(isfolder(liveFolder));
            testCase.verifyTrue(isfolder(uncertainFolder));
            testCase.verifyEqual(inspection.liveSessionCount, 1);
            testCase.verifyEqual(inspection.uncertainSessionCount, 1);
            testCase.verifyEqual(sort(inspection.retention.unsatisfiedAppIds), ...
                ["probe.retention-live"; "probe.retention-uncertain"]);
            testCase.verifyTrue(inspection.retention.unsatisfiedGlobalByteLimit);
            testCase.verifyGreaterThan(inspection.retention.retainedGlobalBytes, 0);
        end

        function initializationAndClosePreserveObservableLeaseOrdering(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            app = journalProbeDefinition();
            resetManifestFault();
            manifestCleanup = onCleanup(@resetManifestFault);
            journal = labkit.app.internal.SessionJournal(app, RootFolder=root, ...
                SessionId="session-initialize-order", FaultInjector=@failActiveMarker);
            initializeFolder = journal.folder();
            testCase.verifyTrue(isfile(fullfile(initializeFolder, "manifest.json")));
            testCase.verifyFalse(isfile(fullfile(initializeFolder, "active.json")));
            testCase.verifyEqual(string(readJson(initializeFolder, "manifest.json").state), "active");
            initializationInspection = labkit.app.internal.SessionJournalArchive.inspect(root);
            testCase.verifyEqual(initializationInspection.uncertainSessionCount, 1);
            testCase.verifyEqual(initializationInspection.recoveredSessionCount, 0);
            testCase.verifyTrue(isfolder(initializeFolder));
            testCase.verifyEqual(string(readJson(initializeFolder, "manifest.json").state), "active");

            resetManifestFault();
            journal = labkit.app.internal.SessionJournal(app, RootFolder=root, ...
                SessionId="session-close-order", FaultInjector=@failSecondManifest);
            closeFolder = journal.folder();
            journal.close();
            testCase.verifyTrue(isfile(fullfile(closeFolder, "active.json")));
            testCase.verifyEqual(string(readJson(closeFolder, "manifest.json").state), "active");
            clear manifestCleanup
        end

        function rejectsMalformedLeaseNonceOption(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            app = journalProbeDefinition();

            testCase.verifyError(@() labkit.app.internal.SessionJournal(app, ...
                RootFolder=root, SessionId="session-invalid-nonce", LeaseNonce=[1, 2]), ...
                "labkit:app:contract:InvalidValue");
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

function failPreflushManifest(stage)
global labkitPreflushManifestFaultCount
if string(stage) ~= "manifest"
    return;
end
labkitPreflushManifestFaultCount = labkitPreflushManifestFaultCount + 1;
if labkitPreflushManifestFaultCount >= 2
    error("labkit:test:JournalManifestFailure", "Intentional preflush manifest failure.");
end
end

function resetPreflushManifestFault()
global labkitPreflushManifestFaultCount
labkitPreflushManifestFaultCount = 0;
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

function marker = markSessionActive(folder, heartbeatAtUtc, nonce, pid)
if nargin < 2
    heartbeatAtUtc = utcOffset(0);
end
if nargin < 3
    nonce = "nonce-active";
end
if nargin < 4
    pid = 41;
end
manifest = readJson(folder, "manifest.json");
manifest.state = "active";
manifest.closedAtUtc = "";
manifest.lease = struct("nonce", string(nonce), "leaseVersion", 1);
writeJson(fullfile(folder, "manifest.json"), manifest);
marker = labkit.app.internal.SessionLease.create( ...
    manifest.sessionId, manifest.appId, "2029-12-31T23:59:00.000Z", ...
    heartbeatAtUtc, nonce, leaseOwnerProbe(pid));
writeJson(fullfile(folder, "active.json"), marker);
end

function probe = leaseOwnerProbe(pid)
if nargin < 1
    pid = 41;
end
probe = struct("host", "fixture-host", "pid", pid, "targetPid", pid, ...
    "processState", "unknown");
end

function manifest = activeLeaseManifest(marker)
manifest = struct("sessionId", marker.sessionId, "appId", marker.appId, ...
    "state", "active", "lease", struct("nonce", marker.nonce, ...
    "leaseVersion", marker.leaseVersion));
end

function probe = leaseProcessProbe(targetPid, state)
probe = struct("host", "fixture-host", "pid", 99, "targetPid", targetPid, ...
    "processState", string(state));
end

function probe = remoteLeaseProbe(targetPid, state)
probe = struct("host", "remote-host", "pid", 99, "targetPid", targetPid, ...
    "processState", string(state));
end

function probe = deadLeaseProbe(targetPid, ~)
probe = leaseProcessProbe(targetPid, "dead");
end

function probe = mixedLeaseProbe(targetPid, ~)
if targetPid == 42
    state = "dead";
elseif targetPid == 43
    state = "unknown";
else
    state = "alive";
end
probe = leaseProcessProbe(targetPid, state);
end

function failActiveMarker(stage)
if string(stage) == "activeMarker"
    error("labkit:test:LeaseMarkerFailure", "Intentional active marker failure.");
end
end

function resetManifestFault()
global labkitSessionJournalManifestCount
labkitSessionJournalManifestCount = 0;
end

function resetLeaseClock(values)
global labkitSessionJournalLeaseClockValues labkitSessionJournalLeaseClockIndex
if nargin < 1
    labkitSessionJournalLeaseClockValues = strings(0, 1);
else
    labkitSessionJournalLeaseClockValues = string(values(:));
end
labkitSessionJournalLeaseClockIndex = 0;
end

function value = nextLeaseClock()
global labkitSessionJournalLeaseClockValues labkitSessionJournalLeaseClockIndex
labkitSessionJournalLeaseClockIndex = labkitSessionJournalLeaseClockIndex + 1;
index = min(labkitSessionJournalLeaseClockIndex, ...
    numel(labkitSessionJournalLeaseClockValues));
value = labkitSessionJournalLeaseClockValues(index);
end

function failSecondManifest(stage)
global labkitSessionJournalManifestCount
if string(stage) ~= "manifest"
    return;
end
labkitSessionJournalManifestCount = labkitSessionJournalManifestCount + 1;
if labkitSessionJournalManifestCount >= 2
    error("labkit:test:LeaseManifestFailure", "Intentional closing manifest failure.");
end
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
