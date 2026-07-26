classdef SessionLogProjectionSpec < matlab.unittest.TestCase
    % SESSIONLOGPROJECTIONSPEC Invariant: standard viewer filtering and clear-view semantics preserve canonical session history.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function filtersTheDefaultViewWithoutChangingCanonicalHistory(testCase)
            runtime = projectionRuntime(testCase);
            cleanup = onCleanup(@() runtime.close());
            runtime.invokeAction("run");
            before = runtime.diagnosticEvents();
            projection = labkit.app.internal.SessionLogProjection( ...
                runtime.diagnosticSnapshot());

            defaultView = projection.view();
            testCase.verifyEqual( ...
                sort(string(defaultView.rows.Level)), ...
                ["INFO"; "WARNING"]);
            testCase.verifyTrue(any( ...
                defaultView.rows.Message == ...
                "Synthetic analysis completed."));
            testCase.verifyTrue(any( ...
                defaultView.rows.Message == ...
                "Synthetic fallback remained usable."));
            testCase.verifyEqual( ...
                numel(defaultView.rootActionLabels), ...
                numel(defaultView.rootActions));
            testCase.verifyFalse(any( ...
                defaultView.rootActionLabels == defaultView.rootActions));
            testCase.verifyTrue(any(contains( ...
                defaultView.rootActionLabels, ...
                "Synthetic analysis completed.")));

            projection.setFilters( ...
                Level="debug", Audience="all", ...
                Category="app.probe.log-projection.analysis", ...
                Search="branch");
            filtered = projection.view();
            testCase.verifyEqual(height(filtered.rows), 1);
            testCase.verifyEqual( ...
                filtered.rows.Message, ...
                "Synthetic branch selected.");
            detail = projection.detail(filtered.rows.Sequence);
            testCase.verifyEqual( ...
                detail.eventName, "analysis.branch_selected");

            projection.clearView();
            testCase.verifyEmpty(projection.view().events);
            testCase.verifyEqual(runtime.diagnosticEvents(), before);

            projection.setFilters( ...
                Level="default", Audience="default", ...
                Category="", RootAction="", Search="");
            runtime.invokeAction("run");
            projection.update(runtime.diagnosticSnapshot());
            afterClear = projection.view();
            testCase.verifyEqual(height(afterClear.rows), 2);
            testCase.verifyGreaterThan( ...
                min(afterClear.rows.Sequence), max([before.sequence]));
            clear cleanup
        end

        function togglesTraceCaptureAndIsolatesAFailingConsumer(testCase)
            runtime = projectionRuntime(testCase);
            cleanup = onCleanup(@() runtime.close());
            token = runtime.subscribeDiagnostics(@failConsumer);

            runtime.invokeAction("run");
            records = runtime.diagnosticEvents();
            names = string({records.eventName});
            testCase.verifyFalse(any(names == "analysis.trace_step"));

            runtime.setTraceCapture(true);
            runtime.invokeAction("run");
            snapshot = runtime.diagnosticSnapshot();
            names = string({snapshot.events.eventName});
            testCase.verifyTrue(snapshot.traceEnabled);
            testCase.verifyTrue(any(names == "trace.capture_enabled"));
            testCase.verifyTrue(any(names == "analysis.trace_step"));

            runtime.unsubscribeDiagnostics(token);
            runtime.setTraceCapture(false);
            snapshot = runtime.diagnosticSnapshot();
            testCase.verifyFalse(snapshot.traceEnabled);
            clear cleanup
        end

        function reportsEveryCaptureAndRetentionLimitation(testCase)
            runtime = projectionRuntime(testCase);
            cleanup = onCleanup(@() runtime.close());
            snapshot = runtime.diagnosticSnapshot();
            snapshot.inMemoryTruncated = true;
            snapshot.journalAvailable = false;
            snapshot.journalState = "unavailable";
            snapshot.droppedRecordCount = 2;
            snapshot.coalescedRecordCount = 3;
            snapshot.expiredSegmentCount = 1;
            snapshot.degradationReason = "write-failure";
            projection = ...
                labkit.app.internal.SessionLogProjection(snapshot);

            notices = projection.view().notices;
            testCase.verifyTrue(any(contains(notices, "TRACE")));
            testCase.verifyTrue(any(contains(notices, ...
                "DEBUG lifecycle")));
            testCase.verifyTrue(any(contains(notices, ...
                "warnings and errors")));
            testCase.verifyTrue(any(contains(notices, "in-memory")));
            testCase.verifyTrue(any(contains(notices, "coalesced")));
            testCase.verifyTrue(any(contains(notices, "expired")));
            testCase.verifyTrue(any(contains(notices, "dropped")));
            testCase.verifyTrue(any(contains(notices, "write-failure")));
            clear cleanup
        end

        function streamsProjectionHealthToConsumersInSequenceOrder(testCase)
            definition = projectionDefinition();
            stream = labkit.app.internal.SessionEventStream( ...
                definition, ProjectionHealthHook=@oneHealthNotice);
            cleanup = onCleanup(@() stream.close());
            projection = labkit.app.internal.SessionLogProjection( ...
                completeSnapshot(stream.captureSnapshot()));
            token = stream.subscribe(@projection.append);

            stream.log( ...
                "info", "analysis.completed", ...
                "Synthetic analysis completed.", ...
                Category="app.probe.log-projection.analysis", ...
                Audience="user");
            projection.setFilters(Level="trace", Audience="all");
            events = projection.view().events;

            testCase.verifyGreaterThan( ...
                min(diff(double([events.sequence]))), 0);
            stream.unsubscribe(token);
            clear cleanup
        end
    end
end

function runtime = projectionRuntime(testCase)
journalRoot = testCase.applyFixture( ...
    matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
definition = projectionDefinition();
runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
    definition, [], struct(), [], ...
    JournalRoot=journalRoot);
end

function definition = projectionDefinition()
layout = labkit.app.layout.workbench({ ...
    labkit.app.layout.button( ...
        "run", "Run", @emitRecords, ...
        Tooltip="Generate synthetic diagnostic records.")});
definition = labkit.app.Definition( ...
    Entrypoint="labkit_LogProjectionProbe_app", ...
    AppId="probe.log-projection", ...
    Title="Log projection probe", Family="Tests", ...
    AppVersion="1.0.0", Updated="2026-07-26", ...
    Requirements=[], Workbench=layout);
end

function applicationState = emitRecords( ...
        applicationState, callbackContext)
category = "app.probe.log-projection.analysis";
callbackContext.log( ...
    "trace", "analysis.trace_step", ...
    "Synthetic trace step.", Category=category, Audience="developer");
callbackContext.log( ...
    "debug", "analysis.branch_selected", ...
    "Synthetic branch selected.", Category=category, Audience="developer");
callbackContext.log( ...
    "info", "analysis.completed", ...
    "Synthetic analysis completed.", Category=category, Audience="user");
callbackContext.log( ...
    "warning", "analysis.fallback_used", ...
    "Synthetic fallback remained usable.", ...
    Category=category, Audience="developer");
end

function failConsumer(~)
error("labkit:test:ConsumerFailure", "Synthetic consumer failure.");
end

function notifications = oneHealthNotice()
notifications = struct( ...
    "eventName", "journal.degraded", ...
    "reason", "write-failure", "count", 0);
end

function snapshot = completeSnapshot(snapshot)
snapshot.journalAvailable = true;
snapshot.journalState = "healthy";
snapshot.droppedRecordCount = 0;
snapshot.coalescedRecordCount = 0;
snapshot.expiredSegmentCount = 0;
snapshot.degradationReason = "";
end
