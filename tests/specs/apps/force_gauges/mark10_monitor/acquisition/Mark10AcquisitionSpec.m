classdef Mark10AcquisitionSpec < matlab.unittest.TestCase
    %MARK10ACQUISITIONSPEC Specify monitor rate and bounded buffer defaults.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function mapsDeclaredRatesAndCreatesEmptyBuffer(testCase)
            buffer = mark10_monitor.acquisition.createBuffer();

            labels = ["10 Hz", "20 Hz", "30 Hz", "40 Hz", "50 Hz"];
            periods = arrayfun(@mark10_monitor.acquisition.ratePeriod, labels);
            testCase.verifyEqual(periods, 1 ./ [10, 20, 30, 40, 50], ...
                "AbsTol", eps);
            testCase.verifyEqual(mark10_monitor.viewRefreshPeriod(), 0.034);
            testCase.verifyEmpty(buffer("plotTime_s"));
            testCase.verifyEqual(buffer("lastRefresh_s"), -Inf);
            testCase.verifyError(@() ...
                mark10_monitor.acquisition.ratePeriod("unsupported"), ...
                "mark10_monitor:InvalidRate");
        end

        function highRateSamplingDoesNotForceOnePresentationPerSample(testCase)
            posts = containers.Map("KeyType", "char", "ValueType", "any");
            posts("count") = 0;
            context = labkittest.createCallbackContext(struct( ...
                "postEvent", @(~, ~) increment(posts)));
            transport = struct( ...
                "Write", @(~) [], "Flush", @() [], ...
                "ReadUntil", @(~, ~) uint8(sprintf('1.00 N\r\n2.00 mm\r\n')), ...
                "ReadFor", @(~) uint8([]), "Pause", @(~) [], ...
                "Close", @() [], "IsOpen", @() true);
            connection = struct( ...
                "Type", "labkit.mark10.connection", "Port", "SYNTHETIC", ...
                "Timeout", 0.01, "Transport", transport, ...
                "Identity", struct(), "Capabilities", struct(), ...
                "Settings", struct(), "RestoreAutoOutput", "AOUT0", ...
                "AcquisitionMode", "Unknown", "SampleCount", uint64(0), ...
                "LastFailure", struct("Status", "", "Message", ""));
            connectionBox = containers.Map( ...
                "KeyType", "char", "ValueType", "any");
            connectionBox("connection") = connection;
            buffer = mark10_monitor.acquisition.createBuffer();
            buffer("lastRefresh_s") = Inf;

            for index = 1:50
                mark10_monitor.acquisition.poll( ...
                    connectionBox, buffer, context);
            end
            testCase.verifyEqual(buffer("sampleCount"), 50);
            testCase.verifyNumElements(buffer("time_s"), 50, ...
                "Every monitoring attempt must remain available for export.");
            testCase.verifyEqual(posts("count"), 0);

            buffer("lastRefresh_s") = -Inf;
            mark10_monitor.acquisition.poll(connectionBox, buffer, context);
            testCase.verifyEqual(posts("count"), 1);
        end

        function serialPollingLeavesAnEventWindowAfterEveryRead(testCase)
            connectionBox = containers.Map( ...
                "KeyType", "char", "ValueType", "any");
            buffer = mark10_monitor.acquisition.createBuffer();
            context = labkittest.createCallbackContext(struct());
            monitorTimer = mark10_monitor.acquisition.createTimer( ...
                connectionBox, buffer, context, 0.02);
            cleanup = onCleanup(@() delete(monitorTimer));

            testCase.verifyEqual(string(monitorTimer.ExecutionMode), ...
                "fixedDelay");
            testCase.verifyEqual(string(monitorTimer.BusyMode), "drop");
            testCase.verifyEqual(monitorTimer.StartDelay, 1);
            testCase.verifyEqual(monitorTimer.Period, 0.02);
            testCase.verifyNotEmpty(monitorTimer.TimerFcn);
            clear cleanup
        end

        function monitoringIsExplicitAndIndependentFromConnection(testCase)
            resources = containers.Map("KeyType", "char", "ValueType", "any");
            cleanups = containers.Map("KeyType", "char", "ValueType", "any");
            resources("mark10Connection") = containers.Map( ...
                "KeyType", "char", "ValueType", "any");
            resources("mark10Buffer") = ...
                mark10_monitor.acquisition.createBuffer();
            backend = struct( ...
                "getResource", @(~, id) resources(char(id)), ...
                "setResource", @(~, id, value, cleanup) ...
                    setResource(resources, cleanups, id, value, cleanup), ...
                "removeResource", @(~, id) ...
                    removeResource(resources, cleanups, id));
            context = labkittest.createCallbackContext(backend);
            state = struct("session", struct( ...
                "connection", struct("connected", true, "status", "Connected."), ...
                "acquisition", struct("rate", "50 Hz", ...
                    "monitoring", false, "retainedValidCount", 0), ...
                "analysis", emptyAnalysis(), ...
                "export", struct("status", "No monitoring data exported.")));

            state = mark10_monitor.acquisition.startMonitoring(state, context);

            testCase.verifyTrue(state.session.connection.connected);
            testCase.verifyTrue(state.session.acquisition.monitoring);
            testCase.verifyTrue(isKey(resources, "mark10Timer"));
            testCase.verifyEqual(string(resources("mark10Timer").Running), "on");
            buffer = resources("mark10Buffer");
            buffer("valid") = [true; false; true];

            state = mark10_monitor.acquisition.stopMonitoring(state, context);

            testCase.verifyTrue(state.session.connection.connected);
            testCase.verifyFalse(state.session.acquisition.monitoring);
            testCase.verifyEqual( ...
                state.session.acquisition.retainedValidCount, 2);
            testCase.verifyFalse(isKey(resources, "mark10Timer"));
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

function increment(posts)
posts("count") = posts("count") + 1;
end

function setResource(resources, cleanups, id, value, cleanup)
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
