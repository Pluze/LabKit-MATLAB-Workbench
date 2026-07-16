classdef labkitProgressPlugin < matlab.unittest.plugins.TestRunnerPlugin
    %LABKITPROGRESSPLUGIN Emit numbered progress lines for CI and batch logs.
    % Expected caller: tests/runLabKitTests.m. Inputs are matlab.unittest
    % pluginData objects. Output is console progress before each test runs.
    % Side effects: writes concise progress lines to stdout.

    properties (Access = private)
        TotalTests = 0
        StartedTests = 0
        CompletedTests = 0
        SuiteTimer = []
        TestTimer = []
        ActiveTestName = ""
        ProgressFile = ""
        ActiveTestFile = ""
        HeartbeatTimer = []
    end

    methods
        function plugin = labkitProgressPlugin(logFolder)
            if nargin < 1 || strlength(string(logFolder)) == 0
                return;
            end
            plugin.ProgressFile = fullfile(string(logFolder), "test-progress.jsonl");
            plugin.ActiveTestFile = fullfile(string(logFolder), "active-test.json");
        end
    end

    methods (Access = protected)
        function runTestSuite(plugin, pluginData)
            plugin.TotalTests = numel(pluginData.TestSuite);
            plugin.StartedTests = 0;
            plugin.CompletedTests = 0;
            plugin.SuiteTimer = tic;
            fprintf("LabKit test progress: 0/%d elapsed=00:00:00 eta=unknown\n", ...
                plugin.TotalTests);
            plugin.recordEvent("suite_start", "", 0);
            plugin.startHeartbeat();
            cleanup = onCleanup(@() plugin.stopHeartbeat());
            runTestSuite@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            plugin.recordEvent("suite_done", "", toc(plugin.SuiteTimer));
            clear cleanup
        end

        function runTest(plugin, pluginData)
            plugin.StartedTests = plugin.StartedTests + 1;
            testIndex = plugin.StartedTests;
            testName = string(pluginData.Name);
            testTimer = tic;
            plugin.ActiveTestName = testName;
            plugin.TestTimer = testTimer;
            plugin.recordEvent("test_start", testName, 0);
            plugin.writeActiveTest("running", testName, 0);
            fprintf("START [%d/%d %5.1f%% elapsed=%s eta=%s] %s\n", ...
                testIndex, plugin.TotalTests, plugin.percentStarted(), ...
                plugin.elapsedText(), plugin.etaText(), testName);
            runTest@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            plugin.CompletedTests = plugin.CompletedTests + 1;
            testElapsed = toc(testTimer);
            fprintf("DONE  [%d/%d %5.1f%% elapsed=%s eta=%s +%s] %s\n", ...
                plugin.CompletedTests, plugin.TotalTests, plugin.percentComplete(), ...
                plugin.elapsedText(), plugin.etaText(), ...
                labkitProgressPlugin.formatSeconds(testElapsed), testName);
            plugin.recordEvent("test_done", testName, testElapsed);
            plugin.writeActiveTest("completed", testName, testElapsed);
            plugin.ActiveTestName = "";
            plugin.TestTimer = [];
        end
    end

    methods (Access = private)
        function text = elapsedText(plugin)
            if isempty(plugin.SuiteTimer)
                text = "00:00:00";
                return;
            end
            text = labkitProgressPlugin.formatSeconds(toc(plugin.SuiteTimer));
        end

        function text = etaText(plugin)
            if isempty(plugin.SuiteTimer) || plugin.CompletedTests <= 0
                text = "unknown";
                return;
            end
            if plugin.CompletedTests >= plugin.TotalTests
                text = "00:00:00";
                return;
            end
            elapsed = toc(plugin.SuiteTimer);
            perTest = elapsed / double(plugin.CompletedTests);
            remaining = perTest * double(plugin.TotalTests - plugin.CompletedTests);
            text = labkitProgressPlugin.formatSeconds(remaining);
        end

        function value = percentStarted(plugin)
            if plugin.TotalTests <= 0
                value = 100;
            else
                value = 100 * double(plugin.StartedTests) / double(plugin.TotalTests);
            end
        end

        function value = percentComplete(plugin)
            if plugin.TotalTests <= 0
                value = 100;
            else
                value = 100 * double(plugin.CompletedTests) / double(plugin.TotalTests);
            end
        end

        function startHeartbeat(plugin)
            plugin.stopHeartbeat();
            try
                plugin.HeartbeatTimer = timer( ...
                    "ExecutionMode", "fixedSpacing", ...
                    "Period", 30, ...
                    "BusyMode", "drop", ...
                    "TimerFcn", @(~, ~) plugin.emitHeartbeat());
                start(plugin.HeartbeatTimer);
            catch
                plugin.HeartbeatTimer = [];
            end
        end

        function stopHeartbeat(plugin)
            timerObj = plugin.HeartbeatTimer;
            plugin.HeartbeatTimer = [];
            if isempty(timerObj)
                return;
            end
            try
                if isvalid(timerObj)
                    stop(timerObj);
                    delete(timerObj);
                end
            catch
            end
        end

        function emitHeartbeat(plugin)
            if strlength(plugin.ActiveTestName) == 0 || isempty(plugin.TestTimer)
                return;
            end
            elapsed = toc(plugin.TestTimer);
            fprintf("HEARTBEAT [%d/%d elapsed=%s test_elapsed=%s] %s\n", ...
                plugin.StartedTests, plugin.TotalTests, plugin.elapsedText(), ...
                labkitProgressPlugin.formatSeconds(elapsed), plugin.ActiveTestName);
            plugin.recordEvent("heartbeat", plugin.ActiveTestName, elapsed);
            plugin.writeActiveTest("running", plugin.ActiveTestName, elapsed);
        end

        function recordEvent(plugin, eventName, testName, testElapsed)
            if strlength(plugin.ProgressFile) == 0
                return;
            end
            payload = plugin.progressPayload(eventName, testName, testElapsed);
            plugin.writeJson(plugin.ProgressFile, payload, "a");
        end

        function writeActiveTest(plugin, status, testName, testElapsed)
            if strlength(plugin.ActiveTestFile) == 0
                return;
            end
            payload = plugin.progressPayload(status, testName, testElapsed);
            plugin.writeJson(plugin.ActiveTestFile, payload, "w");
        end

        function payload = progressPayload(plugin, eventName, testName, testElapsed)
            payload = struct( ...
                "timestamp", char(datetime("now", "TimeZone", "UTC", ...
                    "Format", "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")), ...
                "event", char(string(eventName)), ...
                "test", char(string(testName)), ...
                "started", plugin.StartedTests, ...
                "completed", plugin.CompletedTests, ...
                "total", plugin.TotalTests, ...
                "suiteElapsedSeconds", plugin.suiteElapsedSeconds(), ...
                "testElapsedSeconds", double(testElapsed));
        end

        function elapsed = suiteElapsedSeconds(plugin)
            if isempty(plugin.SuiteTimer)
                elapsed = 0;
            else
                elapsed = toc(plugin.SuiteTimer);
            end
        end

        function writeJson(~, filepath, payload, mode)
            fid = fopen(filepath, mode);
            if fid < 0
                error("LabKit:Tests:ProgressArtifactWrite", ...
                    "Could not write test progress artifact: %s", filepath);
            end
            cleanup = onCleanup(@() fclose(fid));
            fprintf(fid, "%s\n", jsonencode(payload));
            clear cleanup
        end
    end

    methods (Static, Access = private)
        function text = formatSeconds(secondsValue)
            secondsValue = max(0, floor(double(secondsValue)));
            hours = floor(secondsValue / 3600);
            minutes = floor(mod(secondsValue, 3600) / 60);
            secondsValue = mod(secondsValue, 60);
            text = string(sprintf("%02d:%02d:%02d", hours, minutes, secondsValue));
        end
    end
end
