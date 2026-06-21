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
    end

    methods (Access = protected)
        function runTestSuite(plugin, pluginData)
            plugin.TotalTests = numel(pluginData.TestSuite);
            plugin.StartedTests = 0;
            plugin.CompletedTests = 0;
            plugin.SuiteTimer = tic;
            fprintf("LabKit test progress: 0/%d elapsed=00:00:00 eta=unknown\n", ...
                plugin.TotalTests);
            runTestSuite@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
        end

        function runTest(plugin, pluginData)
            plugin.StartedTests = plugin.StartedTests + 1;
            testIndex = plugin.StartedTests;
            testName = string(pluginData.Name);
            testTimer = tic;
            fprintf("START [%d/%d %5.1f%% elapsed=%s eta=%s] %s\n", ...
                testIndex, plugin.TotalTests, plugin.percentStarted(), ...
                plugin.elapsedText(), plugin.etaText(), testName);
            runTest@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            plugin.CompletedTests = plugin.CompletedTests + 1;
            fprintf("DONE  [%d/%d %5.1f%% elapsed=%s eta=%s +%s] %s\n", ...
                plugin.CompletedTests, plugin.TotalTests, plugin.percentComplete(), ...
                plugin.elapsedText(), plugin.etaText(), ...
                labkitProgressPlugin.formatSeconds(toc(testTimer)), testName);
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
