classdef SessionEventStreamSpec < matlab.unittest.TestCase
    %SESSIONEVENTSTREAMSPEC Verify the private Phase 2 canonical event stream.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function retainsMinimalPrivacySafeEventBeforeAnyProjection(testCase)
            stream = labkit.app.internal.SessionEventStream( ...
                loggingProbeDefinition(), SessionId="session-test");
            cleanup = onCleanup(@() stream.close());

            operation = stream.begin("runtime.callback", "callback.run", ...
                "Dispatching callback.", Attributes=struct("bindingId", "run"));
            stream.log("info", "analysis.completed", "Analysis completed.", ...
                Category="app.probe.session-logging.analysisRun", Audience="user", ...
                Attributes=struct("validItemCount", 2));
            stream.finish(operation, "completed");
            records = stream.records();
            completed = records(string({records.eventName}) == "analysis.completed");

            testCase.verifyNumElements(completed, 1);
            testCase.verifyEqual(string(fieldnames(completed)), [ ...
                "schemaVersion"; "sequence"; "timestampUtc"; ...
                "elapsedSeconds"; "severity"; "audience"; "category"; ...
                "eventName"; "message"; "attributes"; "sessionId"; ...
                "appId"; "operationId"; "parentOperationId"; ...
                "rootActionId"; "outcome"; "durationSeconds"; "exception"]);
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
                Attributes=struct("unit", "mV/s", "label", "Nominal (A/B)."));
            records = stream.records();
            retained = records(string({records.eventName}) == "analysis.unit_ratio");

            testCase.verifyNumElements(retained, 1);
            testCase.verifyEqual(retained.attributes.unit, "mV/s");
            testCase.verifyEqual(retained.attributes.label, "Nominal (A/B).");
            testCase.verifyEqual(labkitSessionEventStreamConsumerRecords, ...
                "analysis.unit_ratio");
            clear cleanup resetConsumer
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

function definition = loggingProbeDefinition()
definition = labkit.app.Definition( ...
    "Entrypoint", "labkit_SessionEventStreamProbe_app", ...
    "AppId", "probe.session-event-stream", "Title", "Session stream probe", ...
    "Family", "Tests", "AppVersion", "1.0.0", "Updated", "2026-07-25", ...
    "Requirements", [], "Workbench", labkit.app.layout.workbench({}));
end
