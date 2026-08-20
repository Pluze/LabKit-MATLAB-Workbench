classdef Mark10AcquisitionSpec < matlab.unittest.TestCase
    %MARK10ACQUISITIONSPEC Specify monitor rate and bounded buffer defaults.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function mapsDeclaredRatesAndCreatesEmptyBuffer(testCase)
            buffer = mark10_monitor.acquisition.createBuffer();

            labels = ["10 Hz", "20 Hz", "30 Hz", "40 Hz", "50 Hz"];
            periods = arrayfun(@mark10_monitor.acquisition.ratePeriod, labels);
            testCase.verifyEqual(periods, 1 ./ [10, 20, 30, 40, 50], ...
                "AbsTol", eps);
            testCase.verifyEqual( ...
                mark10_monitor.acquisition.viewRefreshPeriod(), 0.1);
            testCase.verifyEmpty(buffer("plotTime_s"));
            testCase.verifyEqual(buffer("lastRefresh_s"), -Inf);
            testCase.verifyFalse(buffer("refreshPending"));
            testCase.verifyError(@() ...
                mark10_monitor.acquisition.ratePeriod("unsupported"), ...
                "mark10_monitor:InvalidRate");
        end

        function readsOnceWithoutStartingOrRetainingMonitoring(testCase)
            command = containers.Map("KeyType", "char", "ValueType", "any");
            command("value") = "";
            box = containers.Map("KeyType", "char", "ValueType", "any");
            box("connection") = manualReadConnection(command);
            context = labkittest.createCallbackContext(struct( ...
                "getResource", @(~, ~) box, "alert", @(~, ~) []));
            state = struct("session", struct( ...
                "acquisition", struct("monitoring", false, ...
                    "sampleCount", 7, "force_N", NaN, "travel_mm", NaN), ...
                "connection", struct("status", "", "lastFailure", "", ...
                    "acquisitionMode", "Unknown")));

            state = mark10_monitor.acquisition.readOnce(state, context);

            testCase.verifyEqual(state.session.acquisition.force_N, 1);
            testCase.verifyEqual(state.session.acquisition.travel_mm, 2);
            testCase.verifyEqual(state.session.acquisition.sampleCount, 7, ...
                "A manual read must not become monitoring data.");
            testCase.verifyEqual(state.session.connection.status, ...
                "Manual device reading updated.");
        end

        function highRateSamplingDoesNotForceOnePresentationPerSample(testCase)
            posts = containers.Map("KeyType", "char", "ValueType", "any");
            posts("count") = 0;
            context = labkittest.createCallbackContext(struct( ...
                "postEvent", @(~, ~) increment(posts)));
            connectionBox = containers.Map( ...
                "KeyType", "char", "ValueType", "any");
            connectionBox("connection") = struct("AcquisitionMode", "Unknown");
            buffer = mark10_monitor.acquisition.createBuffer();
            buffer("lastRefresh_s") = Inf;
            sample = struct("Valid", true, "Force_N", 1, ...
                "Travel_mm", 2, "ForceRawValue", 1, ...
                "TravelRawValue", 2, "ForceUnit", "N", ...
                "TravelUnit", "mm", "FailureStatus", "", ...
                "AcquisitionMode", "Synchronized n");

            for index = 1:50
                connection = struct("AcquisitionMode", "Synchronized n", ...
                    "SampleCount", uint64(index));
                mark10_monitor.acquisition.receiveSample( ...
                    connectionBox, buffer, context, connection, sample);
            end
            testCase.verifyEqual(buffer("sampleCount"), 50);
            testCase.verifyNumElements(buffer("time_s"), 50, ...
                "Every monitoring attempt must remain available for export.");
            testCase.verifyEqual(posts("count"), 0);

            buffer("lastRefresh_s") = -Inf;
            mark10_monitor.acquisition.receiveSample( ...
                connectionBox, buffer, context, connection, sample);
            testCase.verifyEqual(posts("count"), 1);
            testCase.verifyTrue(buffer("refreshPending"));
            buffer("lastRefresh_s") = -Inf;
            mark10_monitor.acquisition.receiveSample( ...
                connectionBox, buffer, context, connection, sample);
            testCase.verifyEqual(posts("count"), 1, ...
                "An unhandled refresh must coalesce later refresh requests.");
        end

        function monitoringIsExplicitAndIndependentFromConnection(testCase)
            resources = containers.Map("KeyType", "char", "ValueType", "any");
            cleanups = containers.Map("KeyType", "char", "ValueType", "any");
            connectionBox = containers.Map( ...
                "KeyType", "char", "ValueType", "any");
            connectionBox("connection") = samplingConnection();
            serviceCleanup = onCleanup(@() ...
                cancelSamplingService(connectionBox("connection")));
            resources("mark10Connection") = connectionBox;
            resources("mark10Buffer") = ...
                mark10_monitor.acquisition.createBuffer();
            backend = struct( ...
                "getResource", @(~, id) resources(char(id)), ...
                "setResource", @(~, id, value, cleanup) ...
                    setResource(resources, cleanups, id, value, cleanup), ...
                "removeResource", @(~, id) ...
                    removeResource(resources, cleanups, id), ...
                "postEvent", @(~, ~) []);
            context = labkittest.createCallbackContext(backend);
            state = struct("session", struct( ...
                "connection", struct("connected", true, "status", "Connected."), ...
                "acquisition", struct("rate", "50 Hz", ...
                    "monitoring", false, "retainedValidCount", 0, ...
                    "actualRate_Hz", 0), ...
                "cache", struct("plotViewRevision", 0, ...
                    "plotLimits", mark10_monitor.livePlots.defaultLimits(50)), ...
                "analysis", emptyAnalysis(), ...
                "export", struct("status", "No monitoring data exported.")));

            state = mark10_monitor.acquisition.startMonitoring(state, context);

            testCase.verifyTrue(state.session.connection.connected);
            testCase.verifyTrue(state.session.acquisition.monitoring);
            testCase.verifyTrue(isKey(resources, "mark10Sampler"));
            testCase.verifyEqual( ...
                string(resources("mark10Sampler").Type), ...
                "labkit.mark10.sampler");
            sampler = resources("mark10Sampler");
            testCase.verifyEqual( ...
                string(sampler.State("timer").ExecutionMode), "fixedSpacing");
            testCase.verifyEqual( ...
                string(sampler.State("timer").BusyMode), "drop");
            samplerService = sampler.State("service");
            testCase.verifyClass(samplerService("future"), ...
                "parallel.FevalFuture");
            state = mark10_monitor.acquisition.changeRate( ...
                state, "20 Hz", context);
            testCase.verifyEqual(state.session.acquisition.rate, "20 Hz");
            testCase.verifyEqual(sampler.State("period"), 0.05);
            buffer = resources("mark10Buffer");
            buffer("valid") = [true; false; true];

            state = mark10_monitor.acquisition.stopMonitoring(state, context);

            testCase.verifyTrue(state.session.connection.connected);
            testCase.verifyFalse(state.session.acquisition.monitoring);
            testCase.verifyEqual( ...
                state.session.acquisition.retainedValidCount, ...
                sum(buffer("valid")));
            testCase.verifyGreaterThanOrEqual( ...
                state.session.acquisition.retainedValidCount, 2);
            testCase.verifyFalse(isKey(resources, "mark10Sampler"));
            testCase.verifyEqual( ...
                connectionBox("connection").Type, ...
                "labkit.mark10.connection");
            clear serviceCleanup
        end
    end
end

function value = emptyAnalysis()
value = struct("resultRows", {cell(0, 11)}, ...
    "plotStrain_percent", zeros(0, 1), ...
    "plotStress_MPa", zeros(0, 1), ...
    "fitLines", struct("strain_percent", {}, ...
        "stress_MPa", {}, "accepted", {}), ...
    "summary", "", "status", "", "resultRevision", 0, ...
    "dataSource", "None");
end

function value = manualReadConnection(command)
transport = struct( ...
    "Write", @(bytes) captureCommand(command, bytes), ...
    "Flush", @() [], ...
    "ReadUntil", @(~, ~) manualReadResponse(command), ...
    "ReadFor", @(~) uint8([]), "Pause", @(~) [], ...
    "Close", @() [], "IsOpen", @() true);
value = struct("Type", "labkit.mark10.connection", ...
    "Port", "SYNTHETIC", "Timeout", 0.01, ...
    "Transport", transport, "Identity", struct(), ...
    "Capabilities", struct(), "Settings", struct(), ...
    "RestoreAutoOutput", "AOUT0", "AcquisitionMode", "Unknown", ...
    "SampleCount", uint64(0), ...
    "LastFailure", struct("Status", "", "Message", ""));
end

function command = captureCommand(command, bytes)
command("value") = strip(erase(string(native2unicode( ...
    uint8(bytes(:).'), "UTF-8")), char(13)));
end

function raw = manualReadResponse(command)
if command("value") == "n"
    raw = uint8(sprintf('1.00 N\r\n2.00 mm\r\n'));
else
    raw = uint8([]);
end
end

function posts = increment(posts)
posts("count") = posts("count") + 1;
end

function connection = samplingConnection()
events = parallel.pool.PollableDataQueue;
service = containers.Map("KeyType", "char", "ValueType", "any");
service("commands") = [];
service("events") = events;
service("responses") = containers.Map( ...
    "KeyType", "char", "ValueType", "any");
service("nextRequestId") = uint64(0);
service("consumer") = [];
service("metadata") = samplingMetadata();
service("closed") = false;
service("future") = parfeval( ...
    backgroundPool, @fakeSamplingService, 0, events);
ready = poll(events, 10);
assert(~isempty(ready), "Fake Mark-10 driver did not become ready.");
service("commands") = ready.Payload{1};
service("metadata") = ready.Metadata;
connection = ready.Metadata;
connection.Type = "labkit.mark10.connection";
connection.Transport = struct();
connection.Service = service;
end

function cancelSamplingService(connection)
if ~isstruct(connection) || ~isfield(connection, "Service")
    return;
end
future = connection.Service("future");
if isvalid(future) && string(future.State) ~= "finished"
    cancel(future);
end
end

function fakeSamplingService(events)
commands = parallel.pool.PollableDataQueue;
metadata = samplingMetadata();
send(events, samplingEvent("ready", 0, {commands}, metadata));
running = true;
while running
    command = poll(commands, 0.1);
    if isempty(command)
        continue;
    end
    if string(command.Action) == "disconnect"
        running = false;
    end
    send(events, samplingEvent( ...
        "response", command.RequestId, {}, metadata));
end
end

function metadata = samplingMetadata()
metadata = struct("Port", "SYNTHETIC", "Timeout", 3, ...
    "Identity", struct(), "Capabilities", struct( ...
    "CombinedSample", "SUPPORTED"), "Settings", struct(), ...
    "RestoreAutoOutput", "AOUT0", ...
    "AcquisitionMode", "Synchronized n", "SampleCount", uint64(0), ...
    "LastFailure", struct("Status", "", "Message", ""));
end

function value = samplingEvent(type, requestId, payload, metadata)
value = struct("Type", string(type), "RequestId", uint64(requestId), ...
    "Payload", {payload}, "Metadata", metadata);
end

function [resources, cleanups] = setResource( ...
        resources, cleanups, id, value, cleanup)
id = char(id);
resources(id) = value;
cleanups(id) = cleanup;
end

function removeResource(resources, cleanups, id)
id = char(id);
if isKey(resources, id)
    value = resources(id);
    if isKey(cleanups, id) && ~isempty(cleanups(id))
        cleanup = cleanups(id);
        cleanup(value);
    end
    remove(resources, id);
end
if isKey(cleanups, id)
    remove(cleanups, id);
end
end
