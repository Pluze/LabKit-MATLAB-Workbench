classdef SessionEventStreamSpec < matlab.unittest.TestCase
    %SESSIONEVENTSTREAMSPEC Verify the private Phase 2 canonical event stream.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function defaultSessionIdentityDoesNotChangeRng(testCase)
            before = rng;
            stream = labkit.app.internal.SessionEventStream( ...
                loggingProbeDefinition());
            cleanup = onCleanup(@() stream.close());

            testCase.verifyEqual(rng, before);
            clear cleanup
        end

        function retainsMinimalPrivacySafeEventBeforeAnyProjection(testCase)
            stream = labkit.app.internal.SessionEventStream( ...
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

        function rejectsRawPathBeforeItCanEnterTheRetainedRing(testCase)
            global labkitSessionEventStreamConsumerRecords
            labkitSessionEventStreamConsumerRecords = strings(0, 1);
            resetConsumer = onCleanup(@resetTestConsumer);
            folder = string(testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder);
            leaf = "input" + "." + "csv";
            windowsPath = string(fullfile(folder, leaf));
            posixPath = "/" + replace(erase(folder, ":"), "\\", "/") + "/" + leaf;
            posixSingleComponent = "/" + "artifact";
            separator = string(char(92));
            uncPath = separator + separator + "node" + separator + "share" + ...
                separator + leaf;
            unsafeValues = [windowsPath, posixPath, posixSingleComponent, uncPath, leaf];
            stream = labkit.app.internal.SessionEventStream( ...
                loggingProbeDefinition(), ProjectionHook=@recordTestConsumer);
            cleanup = onCleanup(@() stream.close());
            labkitSessionEventStreamConsumerRecords = strings(0, 1);
            before = numel(stream.records());

            for unsafeValue = unsafeValues
                testCase.verifyError(@() stream.log("info", "source.loaded", ...
                    "Loaded " + unsafeValue + ".", ...
                    Category="runtime.source", Audience="developer"), ...
                    "labkit:app:contract:UnsafeLogData");
                testCase.verifyError(@() stream.log("info", "source.loaded", ...
                    "Selected source loaded.", Category="runtime.source", ...
                    Audience="developer", Attributes=struct("source", ...
                    struct("selection", unsafeValue))), ...
                    "labkit:app:contract:UnsafeLogData");
            end

            testCase.verifyEqual(numel(stream.records()), before);
            testCase.verifyEmpty(labkitSessionEventStreamConsumerRecords);
            clear cleanup resetConsumer
        end

        function boundsTheProvisionalInMemoryRing(testCase)
            stream = labkit.app.internal.SessionEventStream( ...
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
            global labkitSessionEventStreamConsumerRecords
            labkitSessionEventStreamConsumerRecords = strings(0, 1);
            resetConsumer = onCleanup(@resetTestConsumer);
            stream = labkit.app.internal.SessionEventStream( ...
                loggingProbeDefinition(), ProjectionHook=@recordTestConsumer);
            cleanup = onCleanup(@() stream.close());
            labkitSessionEventStreamConsumerRecords = strings(0, 1);

            stream.log("info", "analysis.unit_ratio", ...
                "Rate settled at the expected mV/s ratio (A/B).", ...
                Category="app.probe.session-logging.analysisRun", Audience="user", ...
                Attributes=struct("unit", "mV/s", "enum", "nominal-ratio"));
            records = stream.records();
            retained = records(string({records.eventName}) == "analysis.unit_ratio");

            testCase.verifyNumElements(retained, 1);
            testCase.verifyEqual(retained.attributes.unit, "mV/s");
            testCase.verifyEqual(retained.attributes.enum, "nominal-ratio");
            testCase.verifyEqual(labkitSessionEventStreamConsumerRecords, ...
                "analysis.unit_ratio");
            clear cleanup resetConsumer
        end

        function retainsOnlyTheFixedAttributeGrammarAtItsBoundaries(testCase)
            stream = labkit.app.internal.SessionEventStream( ...
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

        function rejectsUnsafeAttributeShapesAndSemanticsBeforeRetention(testCase)
            stream = labkit.app.internal.SessionEventStream( ...
                loggingProbeDefinition());
            cleanup = onCleanup(@() stream.close());
            before = numel(stream.records());
            rejected = { ...
                struct("count", [1, 2]), struct("count", NaN), ...
                struct("count", Inf), struct("count", logical([true, false])), ...
                struct("enum", {{"safe"}}), struct("count", table(1)), ...
                struct("count", datetime("now")), struct("count", @sin), ...
                struct("freeText", "safe-token"), struct("subject", 1), ...
                struct("bindingId", "run"), struct("sourceAlias", "untrusted-token"), ...
                struct("sourceAlias", "source-" + string(repmat('1', 1, 64))), ...
                struct("enum", string(missing)), ...
                struct("sampleCount", "one"), ...
                struct("unit", "10mV"), struct("unit", "mV per s"), ...
                struct("nested", struct("count", 1)), ...
                struct("dimensions", struct()), ...
                struct("dimensions", struct("x", 0)), ...
                struct("dimensions", struct("x", [1, 2])), ...
                dimensionsWithFiveAxes(), attributesWithSeventeenFields(), ...
                attributesWithThirteenRootFieldsAndFourAxes(), ...
                attributesAtCanonicalByteCount(1025)};

            for index = 1:numel(rejected)
                testCase.verifyError(@() stream.log("info", "analysis.rejected", ...
                    "Rejected attribute payload.", Category="runtime.lifecycle", ...
                    Audience="developer", Attributes=rejected{index}), ...
                    "labkit:app:contract:UnsafeLogData");
            end
            testCase.verifyEqual(numel(stream.records()), before);
            clear cleanup
        end

        function rejectsUnsafeAttributesWithoutChangingRingHookOrJournal(testCase)
            global labkitAttributePrivacyJournal labkitAttributePrivacyHookCount
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkit.app.internal.SessionJournal(loggingProbeDefinition(), ...
                RootFolder=root, SessionId="session-attribute-privacy", ...
                BufferRecordLimit=1);
            labkitAttributePrivacyJournal = journal;
            labkitAttributePrivacyHookCount = 0;
            globalCleanup = onCleanup(@resetAttributePrivacyProjection);
            journalCleanup = onCleanup(@() journal.close());
            stream = labkit.app.internal.SessionEventStream(loggingProbeDefinition(), ...
                SessionId="session-attribute-privacy", ...
                ProjectionHook=@persistAttributePrivacyRecord);
            streamCleanup = onCleanup(@() stream.close());
            labkitAttributePrivacyHookCount = 0;
            beforeRecords = numel(stream.records());
            beforeJournal = journalText(journal.folder());

            testCase.verifyError(@() stream.log("info", "analysis.rejected", ...
                "Rejected attribute payload.", Category="runtime.lifecycle", ...
                Audience="developer", Attributes=struct("sampleId", 1)), ...
                "labkit:app:contract:UnsafeLogData");

            testCase.verifyEqual(numel(stream.records()), beforeRecords);
            testCase.verifyEqual(labkitAttributePrivacyHookCount, 0);
            testCase.verifyEqual(journalText(journal.folder()), beforeJournal);
            clear streamCleanup journalCleanup globalCleanup
        end
    end
end

function recordTestConsumer(record)
global labkitSessionEventStreamConsumerRecords
labkitSessionEventStreamConsumerRecords(end + 1) = record.eventName;
end

function resetTestConsumer()
global labkitSessionEventStreamConsumerRecords
labkitSessionEventStreamConsumerRecords = strings(0, 1);
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

function attributes = attributesAtCanonicalByteCount(targetBytes)
attributes = struct();
prefixes = "metric" + string(1:16);
for index = 1:numel(prefixes)
    attributes.(char(prefixes(index))) = index;
end
remaining = targetBytes - canonicalAttributeBytes(attributes);
for index = 1:16
    prefix = prefixes(index);
    padding = min(remaining, 64 - strlength(prefix));
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
global labkitAttributePrivacyJournal labkitAttributePrivacyHookCount
labkitAttributePrivacyHookCount = labkitAttributePrivacyHookCount + 1;
labkitAttributePrivacyJournal.append(record);
end

function resetAttributePrivacyProjection()
global labkitAttributePrivacyJournal labkitAttributePrivacyHookCount
labkitAttributePrivacyJournal = [];
labkitAttributePrivacyHookCount = 0;
end

function text = journalText(folder)
segments = dir(fullfile(folder, "events-*.jsonl"));
text = strings(0, 1);
for index = 1:numel(segments)
    text(end + 1, 1) = string(fileread(fullfile(segments(index).folder, segments(index).name)));
end
end

function definition = loggingProbeDefinition()
definition = labkit.app.Definition( ...
    "Entrypoint", "labkit_SessionEventStreamProbe_app", ...
    "AppId", "probe.session-event-stream", "Title", "Session stream probe", ...
    "Family", "Tests", "AppVersion", "1.0.0", "Updated", "2026-07-25", ...
    "Requirements", [], "Workbench", labkit.app.layout.workbench({}));
end
