classdef SessionEventStreamSpec < matlab.unittest.TestCase
    %SESSIONEVENTSTREAMSPEC Verify the private Phase 2 canonical event stream.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function defaultSessionIdentityDoesNotChangeRng(testCase)
            before = rng;
            stream = labkit.app.internal.diagnostics.SessionEventStream( ...
                loggingProbeDefinition());
            cleanup = onCleanup(@() stream.close());

            testCase.verifyEqual(rng, before);
            clear cleanup
        end

        function retainsCanonicalEventBeforeAnyProjection(testCase)
            stream = labkit.app.internal.diagnostics.SessionEventStream( ...
                loggingProbeDefinition(), SessionId="session-test");
            cleanup = onCleanup(@() stream.close());

            operation = stream.begin("runtime.callback", "callback.run", ...
                "Dispatching callback.", Attributes=struct("runtimeAlias", "run"));
            stream.log("info", "analysis.completed", "Analysis completed.", ...
                Category="app.probe.session-logging.analysisRun", Audience="user", ...
                Attributes=struct("validItemCount", 2));
            stream.finish(operation, "completed", "committed");
            records = stream.records();
            completed = records(string({records.eventName}) == "analysis.completed");

            testCase.verifyNumElements(completed, 1);
            testCase.verifyEqual(string(fieldnames(completed)), [ ...
                "schemaVersion"; "sequence"; "timestampUtc"; ...
                "elapsedSeconds"; "severity"; "audience"; "category"; ...
                "eventName"; "message"; "attributes"; "sessionId"; ...
                "appId"; "operationId"; "parentOperationId"; ...
                "rootActionId"; "operationResult"; "stateDisposition"; ...
                "durationSeconds"; "exception"]);
            testCase.verifyEqual(completed.sessionId, "session-test");
            testCase.verifyEqual(completed.attributes.validItemCount, 2);
            testCase.verifyEqual(completed.operationId, operation.Id);
            testCase.verifyEqual(completed.rootActionId, operation.RootActionId);
            clear cleanup
        end

        function retainsRawPathsInRingAndProjection(testCase)
            testfixtures.StateStore.set("eventConsumerRecords", strings(0, 1));
            resetConsumer = onCleanup(@resetTestConsumer);
            sourcePath = "/synthetic/input.csv";
            stream = labkit.app.internal.diagnostics.SessionEventStream( ...
                loggingProbeDefinition(), ProjectionHook=@recordTestConsumer);
            cleanup = onCleanup(@() stream.close());
            testfixtures.StateStore.set("eventConsumerRecords", strings(0, 1));

            stream.log("info", "source.loaded", ...
                "Loaded " + sourcePath + ".", ...
                Category="runtime.source", Audience="developer", ...
                Attributes=struct("sourcePath", sourcePath));

            records = stream.records();
            retained = records(end);
            testCase.verifyEqual(retained.message, ...
                "Loaded /synthetic/input.csv.");
            testCase.verifyEqual(retained.attributes.sourcePath, sourcePath);
            testCase.verifyEqual( ...
                testfixtures.StateStore.get("eventConsumerRecords"), ...
                "source.loaded");
            clear cleanup resetConsumer
        end

        function boundsTheProvisionalInMemoryRing(testCase)
            stream = labkit.app.internal.diagnostics.SessionEventStream( ...
                loggingProbeDefinition());
            cleanup = onCleanup(@() stream.close());

            for index = 1:512
                stream.log("debug", "runtime.tick", "Tick recorded.", ...
                    Category="runtime.lifecycle", Audience="developer", ...
                    Attributes=struct("ordinal", index));
            end
            records = stream.records();

            testCase.verifyNumElements(records, 512);
            testCase.verifyEqual(records(1).sequence, 2);
            testCase.verifyEqual(records(end).sequence, 513);
            clear cleanup
        end

        function retainsUnitRatiosAndOrdinaryPunctuation(testCase)
            testfixtures.StateStore.set("eventConsumerRecords", strings(0, 1));
            resetConsumer = onCleanup(@resetTestConsumer);
            stream = labkit.app.internal.diagnostics.SessionEventStream( ...
                loggingProbeDefinition(), ProjectionHook=@recordTestConsumer);
            cleanup = onCleanup(@() stream.close());
            testfixtures.StateStore.set("eventConsumerRecords", strings(0, 1));

            stream.log("info", "analysis.unit_ratio", ...
                "Rate settled at the expected mV/s ratio (A/B).", ...
                Category="app.probe.session-logging.analysisRun", Audience="user", ...
                Attributes=struct("unit", "mV/s", "enum", "nominal-ratio"));
            records = stream.records();
            retained = records(string({records.eventName}) == "analysis.unit_ratio");

            testCase.verifyNumElements(retained, 1);
            testCase.verifyEqual(retained.attributes.unit, "mV/s");
            testCase.verifyEqual(retained.attributes.enum, "nominal-ratio");
            testCase.verifyEqual(testfixtures.StateStore.get("eventConsumerRecords"), ...
                "analysis.unit_ratio");
            clear cleanup resetConsumer
        end

        function retainsOnlyTheFixedAttributeGrammarAtItsBoundaries(testCase)
            stream = labkit.app.internal.diagnostics.SessionEventStream( ...
                loggingProbeDefinition());
            cleanup = onCleanup(@() stream.close());
            attributes = boundedSafeAttributes();

            stream.log("info", "analysis.attribute_boundary", ...
                "Attribute grammar accepted.", ...
                Category="app.probe.session-logging.analysisRun", Audience="user", ...
                Attributes=attributes);
            stream.log("debug", "analysis.attribute_byte_boundary", ...
                "Canonical byte boundary accepted.", Category="runtime.lifecycle", ...
                Audience="developer", Attributes=attributesAtCanonicalByteCount(1024));
            units = ["mV/s", "kOhm", "M" + string(char(8486)), ...
                string(char(181)) + "m", string(char(956)) + "m", ...
                string(char(176)) + "C", "%", "a.u.", "1", ...
                "mA/cm^2", "Ohm*cm^2", "s^-1"];
            for unit = units
                stream.log("debug", "analysis.unit_token", "Unit token accepted.", ...
                    Category="runtime.lifecycle", Audience="developer", ...
                    Attributes=struct("unit", unit));
            end
            records = stream.records();
            retained = records(string({records.eventName}) == ...
                "analysis.attribute_boundary");

            testCase.verifyNumElements(retained, 1);
            testCase.verifyEqual(numel(fieldnames(retained.attributes)), 12);
            testCase.verifyEqual(retained.attributes.dimensions, ...
                struct("samples", 2, "y", 3, "z", 4, "t", 5));
            testCase.verifyEqual(retained.attributes.sourceAlias, "source-1");
            clear cleanup
        end

        function acceptsSerializableDiagnosticAttributeShapes(testCase)
            stream = labkit.app.internal.diagnostics.SessionEventStream( ...
                loggingProbeDefinition());
            cleanup = onCleanup(@() stream.close());
            attributes = struct("values", [1 2 3], ...
                "nested", struct("sourcePath", "/synthetic/input.csv"), ...
                "labels", ["alpha", "beta"]);

            stream.log("info", "analysis.recorded", ...
                "Recorded complete diagnostic attributes.", ...
                Category="runtime.lifecycle", Audience="developer", ...
                Attributes=attributes);

            records = stream.records();
            testCase.verifyEqual(records(end).attributes, attributes);
            clear cleanup
        end

        function persistsCompleteAttributesToTheJournal(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkit.app.internal.diagnostics.SessionJournal(loggingProbeDefinition(), ...
                RootFolder=root, SessionId="session-attribute-privacy", ...
                BufferRecordLimit=1);
            testfixtures.StateStore.set("attributePrivacyJournal", journal);
            testfixtures.StateStore.set("attributePrivacyHookCount", 0);
            globalCleanup = onCleanup(@resetAttributePrivacyProjection);
            journalCleanup = onCleanup(@() journal.close());
            stream = labkit.app.internal.diagnostics.SessionEventStream(loggingProbeDefinition(), ...
                SessionId="session-attribute-privacy", ...
                ProjectionHook=@persistAttributePrivacyRecord);
            streamCleanup = onCleanup(@() stream.close());
            testfixtures.StateStore.set("attributePrivacyHookCount", 0);
            stream.log("info", "analysis.recorded", ...
                "Loaded /synthetic/input.csv.", Category="runtime.lifecycle", ...
                Audience="developer", Attributes=struct( ...
                "sourcePath", "/synthetic/input.csv", "values", [1 2 3]));
            journal.flush();

            retained = journalText(journal.folder());
            testCase.verifyEqual( ...
                testfixtures.StateStore.get("attributePrivacyHookCount"), 1);
            testCase.verifyTrue(contains(retained, "/synthetic/input.csv"));
            testCase.verifyTrue(contains(retained, "values"));
            testCase.verifyTrue(contains(retained, "[1,2,3]"));
            clear streamCleanup journalCleanup globalCleanup
        end

        function retainsClosedNonrecursiveProjectionHealthNotifications(testCase)
            resetProjectionHealthFixture();
            cleanup = onCleanup(@resetProjectionHealthFixture);
            stream = labkit.app.internal.diagnostics.SessionEventStream(loggingProbeDefinition(), ...
                ProjectionHook=@countProjectionHook, ...
                ProjectionHealthHook=@nextProjectionHealthNotification);
            streamCleanup = onCleanup(@() stream.close());
            testfixtures.StateStore.set("projectionHealthNotifications", struct( ...
                "eventName", "journal.records_dropped", ...
                "reason", "write-failure", "count", 2));

            stream.log("info", "analysis.projection", "Projection retained.", ...
                Category="runtime.lifecycle", Audience="developer");
            stream.refreshProjectionHealth();
            records = stream.records();
            dropped = records(string({records.eventName}) == "journal.records_dropped");

            testCase.verifyNumElements(dropped, 1);
            testCase.verifyEqual(dropped.attributes.reason, "write-failure");
            testCase.verifyEqual(dropped.attributes.count, 2);
            testCase.verifyEqual(testfixtures.StateStore.get("projectionHookCount"), 2);
            clear streamCleanup cleanup
        end

        function isolatesMalformedProjectionHealthNotifications(testCase)
            invalid = { ...
                struct("eventName", "analysis.injected", "reason", "write-failure", "count", 1), ...
                struct("eventName", "journal.degraded", "reason", "write-failure", "count", NaN), ...
                struct("eventName", "journal.records_dropped", "reason", "write-failure", "count", 0), ...
                struct("eventName", "journal.records_dropped", "reason", "free text", "count", 1)};
            for index = 1:numel(invalid)
                resetProjectionHealthFixture();
                cleanup = onCleanup(@resetProjectionHealthFixture);
                stream = labkit.app.internal.diagnostics.SessionEventStream(loggingProbeDefinition(), ...
                    ProjectionHealthHook=@nextProjectionHealthNotification);
                streamCleanup = onCleanup(@() stream.close());
                testfixtures.StateStore.set( ...
                    "projectionHealthNotifications", invalid{index});

                stream.refreshProjectionHealth();
                stream.log("info", "analysis.after_health_fault", ...
                    "Caller remains isolated.", Category="runtime.lifecycle", ...
                    Audience="developer");
                records = stream.records();
                degraded = records(string({records.eventName}) == "journal.degraded");

                testCase.verifyNumElements(degraded, 1);
                testCase.verifyEqual(degraded.attributes.reason, "health-unavailable");
                testCase.verifyFalse(any(string({records.eventName}) == "analysis.injected"));
                clear streamCleanup cleanup
            end
        end

        function surfacesJournalProjectionFailureWithoutRecursing(testCase)
            resetProjectionHealthFixture();
            fixtureCleanup = onCleanup(@resetProjectionHealthFixture);
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkit.app.internal.diagnostics.SessionJournal(loggingProbeDefinition(), ...
                RootFolder=root, SessionId="session-projection-failure");
            journalCleanup = onCleanup(@() journal.close());
            projection = labkit.app.internal.diagnostics.SessionJournalProjection( ...
                journal, @failProjectionDelivery);
            stream = labkit.app.internal.diagnostics.SessionEventStream(loggingProbeDefinition(), ...
                SessionId="session-projection-failure", ...
                ProjectionHook=@projection.project, ...
                ProjectionHealthHook=@projection.drainHealth);
            streamCleanup = onCleanup(@() stream.close());
            testfixtures.StateStore.set("projectionDeliveryFailures", [true, true]);
            testfixtures.StateStore.set("projectionDeliveryIndex", 0);
            operation = stream.begin("runtime.callback", "callback.delivery", ...
                "Delivering callback.");

            stream.log("info", "analysis.after_projection_failure", ...
                "Caller remains isolated.", Category="runtime.lifecycle", ...
                Audience="developer", Operation=operation);
            records = stream.records();
            trigger = records(string({records.eventName}) == "callback.delivery.started");
            degraded = records(string({records.eventName}) == "journal.degraded");
            dropped = records(string({records.eventName}) == "journal.records_dropped");

            testCase.verifyNumElements(degraded, 1);
            testCase.verifyEqual(degraded.attributes.reason, "projection-failure");
            testCase.verifyEqual(degraded.operationId, trigger.operationId);
            testCase.verifyEqual(degraded.parentOperationId, trigger.parentOperationId);
            testCase.verifyEqual(degraded.rootActionId, trigger.rootActionId);
            testCase.verifyNumElements(dropped, 2);
            dropAttributes = [dropped.attributes];
            testCase.verifyEqual([dropAttributes.count], [1, 1]);
            testCase.verifyEqual(dropped(1).operationId, trigger.operationId);
            testCase.verifyEqual(dropped(1).parentOperationId, trigger.parentOperationId);
            testCase.verifyEqual(dropped(1).rootActionId, trigger.rootActionId);
            testCase.verifyNotEmpty(degraded.message);
            testCase.verifyNotEmpty(dropped(1).message);
            testCase.verifyNotEqual(degraded.message, dropped(1).message);
            testCase.verifyTrue(any(string({records.eventName}) == ...
                "analysis.after_projection_failure"));
            testCase.verifyEmpty(dir(fullfile(journal.folder(), "events-*.jsonl")));
            stream.refreshProjectionHealth();
            records = stream.records();
            testCase.verifyNumElements(records( ...
                string({records.eventName}) == "journal.records_dropped"), 2);
            clear streamCleanup journalCleanup fixtureCleanup
        end

        function reportsProjectionRecoveryAndLaterFailureAsNewTransition(testCase)
            resetProjectionHealthFixture();
            fixtureCleanup = onCleanup(@resetProjectionHealthFixture);
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkit.app.internal.diagnostics.SessionJournal(loggingProbeDefinition(), ...
                RootFolder=root, SessionId="session-projection-recovery");
            journalCleanup = onCleanup(@() journal.close());
            projection = labkit.app.internal.diagnostics.SessionJournalProjection( ...
                journal, @failProjectionDelivery);
            stream = labkit.app.internal.diagnostics.SessionEventStream(loggingProbeDefinition(), ...
                SessionId="session-projection-recovery", ...
                ProjectionHook=@projection.project, ...
                ProjectionHealthHook=@projection.drainHealth);
            streamCleanup = onCleanup(@() stream.close());
            testfixtures.StateStore.set( ...
                "projectionDeliveryFailures", [true, false, true]);
            testfixtures.StateStore.set("projectionDeliveryIndex", 0);

            stream.log("info", "analysis.projection_first", "First delivery.", ...
                Category="runtime.lifecycle", Audience="developer");
            stream.log("info", "analysis.projection_recovery", "Recovered delivery.", ...
                Category="runtime.lifecycle", Audience="developer");
            stream.log("info", "analysis.projection_second", "Second delivery.", ...
                Category="runtime.lifecycle", Audience="developer");
            stream.refreshProjectionHealth();
            records = stream.records();
            degraded = records(string({records.eventName}) == "journal.degraded");
            dropped = records(string({records.eventName}) == "journal.records_dropped");
            dropAttributes = [dropped.attributes];

            testCase.verifyNumElements(degraded, 2);
            testCase.verifyNumElements(dropped, 2);
            testCase.verifyEqual(sum([dropAttributes.count]), 2);
            testCase.verifyTrue(all(string({dropAttributes.reason}) == "projection-failure"));
            clear streamCleanup journalCleanup fixtureCleanup
        end

        function isolatesProjectionHealthHookThrows(testCase)
            projectionHealthThrowCounter("reset");
            stream = labkit.app.internal.diagnostics.SessionEventStream(loggingProbeDefinition(), ...
                ProjectionHealthHook=@() projectionHealthThrowCounter("throw"));
            cleanup = onCleanup(@() stream.close());
            records = stream.records();
            degraded = records(string({records.eventName}) == "journal.degraded");

            stream.log("info", "analysis.after_health_hook_throw", ...
                "Caller remains isolated.", Category="runtime.lifecycle", ...
                Audience="developer");
            stream.close();
            records = stream.records();
            testCase.verifyNumElements(degraded, 1);
            testCase.verifyEqual(degraded.attributes.reason, "health-unavailable");
            testCase.verifyTrue(any(string({records.eventName}) == ...
                "analysis.after_health_hook_throw"));
            testCase.verifyNumElements(records( ...
                string({records.eventName}) == "journal.degraded"), 1);
            testCase.verifyEqual(projectionHealthThrowCounter("count"), 1);
            clear cleanup
        end

        function reportsWrapperCloseFailureOnceWithoutARecordDrop(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkit.app.internal.diagnostics.SessionJournal(loggingProbeDefinition(), ...
                RootFolder=root, SessionId="session-projection-close-failure");
            cleanup = onCleanup(@() journal.close());
            projection = labkit.app.internal.diagnostics.SessionJournalProjection( ...
                journal, @failProjectionCloseDelivery);

            projection.close();
            notifications = projection.drainHealth();
            repeated = projection.drainHealth();

            testCase.verifyNumElements(notifications, 1);
            testCase.verifyEqual(notifications.eventName, "journal.degraded");
            testCase.verifyEqual(notifications.reason, "projection-failure");
            testCase.verifyEqual(notifications.count, 0);
            testCase.verifyEmpty(repeated);
            clear cleanup
        end

        function closeSequenceRefreshesHealthAfterProjectionFailure(testCase)
                        resetProjectionHealthFixture();
            cleanup = onCleanup(@resetProjectionHealthFixture);
            stream = labkit.app.internal.diagnostics.SessionEventStream(loggingProbeDefinition(), ...
                ProjectionHealthHook=@nextProjectionHealthNotification);

            stream.close();
            try
                failClosingProjection();
            catch cause
                testCase.verifyEqual(string(cause.identifier), ...
                    "labkit:test:ProjectionCloseFailure");
            end
            stream.refreshProjectionHealth();
            records = stream.records();
            names = string({records.eventName});
            sessionClosedIndex = find(names == "session.closed", 1);
            degraded = records(names == "journal.degraded");
            stream.close();
            stream.refreshProjectionHealth();

            testCase.verifyNotEmpty(sessionClosedIndex);
            testCase.verifyNumElements(degraded, 1);
            testCase.verifyEqual(degraded.attributes.reason, "projection-failure");
            testCase.verifyGreaterThan(find(names == "journal.degraded", 1), ...
                sessionClosedIndex);
            afterSecondClose = stream.records();
            testCase.verifyNumElements(afterSecondClose( ...
                string({afterSecondClose.eventName}) == "journal.degraded"), 1);
            clear cleanup
        end
    end
end

function recordTestConsumer(record)
records = testfixtures.StateStore.get("eventConsumerRecords", strings(0, 1));
testfixtures.StateStore.set("eventConsumerRecords", [records; string(record.eventName)]);
end

function resetTestConsumer()
testfixtures.StateStore.reset("eventConsumerRecords");
end

function countProjectionHook(~)
count = testfixtures.StateStore.get("projectionHookCount", 0);
testfixtures.StateStore.set("projectionHookCount", count + 1);
end

function notifications = nextProjectionHealthNotification()
notifications = testfixtures.StateStore.get("projectionHealthNotifications", []);
testfixtures.StateStore.set("projectionHealthNotifications", []);
end

function resetProjectionHealthFixture()
testfixtures.StateStore.set("projectionHookCount", 0);
testfixtures.StateStore.set("projectionHealthNotifications", []);
testfixtures.StateStore.set("projectionDeliveryFailures", false(1, 0));
testfixtures.StateStore.set("projectionDeliveryIndex", 0);
end

function failProjectionDelivery(stage)
if string(stage) ~= "project"
    return;
end
index = testfixtures.StateStore.get("projectionDeliveryIndex", 0) + 1;
failures = testfixtures.StateStore.get( ...
    "projectionDeliveryFailures", false(1, 0));
testfixtures.StateStore.set("projectionDeliveryIndex", index);
if index > numel(failures) || ~failures(index)
    return;
end
error("labkit:test:ProjectionDeliveryFailure", "Intentional projection delivery failure.");
end

function value = projectionHealthThrowCounter(action)
persistent count
if isempty(count)
    count = 0;
end
if action == "reset"
    count = 0;
    value = [];
elseif action == "count"
    value = count;
elseif action == "throw"
    count = count + 1;
    error("labkit:test:ProjectionHealthFailure", "Intentional health reader failure.");
else
    error("labkit:test:InvariantFailure", "Unknown projection health fixture action.");
end
end

function failProjectionCloseDelivery(stage)
if string(stage) == "close"
    error("labkit:test:ProjectionCloseFailure", "Intentional projection close failure.");
end
end

function failClosingProjection()
testfixtures.StateStore.set("projectionHealthNotifications", struct( ...
    "eventName", "journal.degraded", ...
    "reason", "projection-failure", "count", 0));
error("labkit:test:ProjectionCloseFailure", "Intentional projection close failure.");
end

function attributes = boundedSafeAttributes()
attributes = struct("enum", "normal", "unit", "mV/s", "reason", "fallback", ...
    "runtimeAlias", "run", "sourceAlias", "source-1", ...
    "dimensions", struct("samples", 2, "y", 3, "z", 4, "t", 5), ...
    "validItemCount", 2, "ordinal", 1, "durationSeconds", 0.5, ...
    "sampleCount", 1, "signalCount", 1, "fileCount", 1);
end

function attributes = dimensionsWithFiveAxes()
attributes = struct("dimensions", struct("a", 1, "b", 1, "c", 1, "d", 1, "e", 1));
end

function attributes = attributesWithSeventeenFields()
attributes = struct();
for index = 1:17
    attributes.("count" + string(index)) = index;
end
end

function attributes = attributesWithThirteenRootFieldsAndFourAxes()
attributes = struct("dimensions", struct("x", 1, "y", 1, "z", 1, "t", 1));
for index = 1:12
    attributes.("metric" + string(index)) = index;
end
end

function attributes = attributeWithOverlongKey()
attributes = struct();
name = "metric" + string(repmat('x', 1, 64 - strlength("metric")));
attributes.(char(name)) = 1;
end

function attributes = attributesAtCanonicalByteCount(targetBytes)
attributes = struct();
prefixes = "metric" + string(1:16);
for index = 1:numel(prefixes)
    attributes.(char(prefixes(index))) = index;
end
remaining = targetBytes - canonicalAttributeBytes(attributes);
for index = 1:16
    prefix = prefixes(index);
    padding = min(remaining, 63 - strlength(prefix));
    if padding == 0
        continue;
    end
    attributes = rmfield(attributes, char(prefix));
    key = prefix + string(repmat('x', 1, padding));
    attributes.(char(key)) = index;
    remaining = targetBytes - canonicalAttributeBytes(attributes);
end
if remaining ~= 0 || canonicalAttributeBytes(attributes) ~= targetBytes
    error("labkit:test:AttributeByteFixture", ...
        "Could not construct the requested canonical attribute byte boundary.");
end
end

function count = canonicalAttributeBytes(attributes)
count = numel(unicode2native(jsonencode(orderfields(attributes)), "UTF-8"));
end

function persistAttributePrivacyRecord(record)
count = testfixtures.StateStore.get("attributePrivacyHookCount", 0);
testfixtures.StateStore.set("attributePrivacyHookCount", count + 1);
journal = testfixtures.StateStore.get("attributePrivacyJournal");
journal.append(record);
end

function resetAttributePrivacyProjection()
testfixtures.StateStore.reset( ...
    "attributePrivacyJournal", "attributePrivacyHookCount");
end

function text = journalText(folder)
segments = dir(fullfile(folder, "events-*.jsonl"));
text = strings(numel(segments), 1);
for index = 1:numel(segments)
    text(index, 1) = string(fileread( ...
        fullfile(segments(index).folder, segments(index).name)));
end
end

function definition = loggingProbeDefinition()
definition = labkit.app.Definition( ...
    "Entrypoint", "labkit_SessionEventStreamProbe_app", ...
    "AppId", "probe.session-event-stream", "Title", "Session stream probe", ...
    "Family", "Tests", "AppVersion", "1.0.0", "Updated", "2026-07-25", ...
    "Requirements", [], "Workbench", labkit.app.layout.workbench({}));
end
