classdef ProgressPlugin < matlab.unittest.plugins.TestRunnerPlugin
    %PROGRESSPLUGIN Write run-centered progress events and an active-test snapshot.
    %   PLUGIN = labkittest.ProgressPlugin(RUNFOLDER) records suite and test
    %   lifecycle events in RUNFOLDER/events.jsonl and writes the current
    %   structured state to RUNFOLDER/active-test.json. The plugin also prints
    %   concise progress lines for interactive and CI logs.

    properties (Access = private)
        RunFolder
        Total = 0
        Started = 0
        Completed = 0
        SuiteTimer = []
        TestTimer = []
        Current = ""
    end

    methods
        function plugin = ProgressPlugin(runFolder)
            plugin.RunFolder = string(runFolder);
        end
    end

    methods (Access = protected)
        function runTestSuite(plugin, pluginData)
            plugin.Total = numel(pluginData.TestSuite);
            plugin.SuiteTimer = tic;
            plugin.record("suite_start", "", 0);
            plugin.writeActive("starting", "", 0);
            fprintf("LabKit test progress: 0/%d eta=unknown\n", plugin.Total);
            runTestSuite@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            plugin.record("suite_done", "", 0);
            plugin.writeActive("finished", "", 0);
        end

        function runTest(plugin, pluginData)
            plugin.Started = plugin.Started + 1;
            plugin.Current = string(pluginData.Name);
            plugin.TestTimer = tic;
            plugin.record("test_start", plugin.Current, 0);
            plugin.writeActive("running", plugin.Current, 0);
            fprintf("START [%d/%d eta=%s] %s\n", plugin.Started, plugin.Total, ...
                plugin.etaText(), plugin.Current);
            runTest@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            plugin.Completed = plugin.Completed + 1;
            elapsed = toc(plugin.TestTimer);
            plugin.record("test_done", plugin.Current, elapsed);
            plugin.writeActive("completed", plugin.Current, elapsed);
            fprintf("DONE  [%d/%d eta=%s] %s\n", plugin.Completed, plugin.Total, ...
                plugin.etaText(), plugin.Current);
            plugin.Current = "";
            plugin.TestTimer = [];
        end
    end

    methods (Access = private)
        function record(plugin, eventName, testName, testElapsed)
            plugin.appendJson("events.jsonl", plugin.payload(eventName, testName, testElapsed));
        end

        function writeActive(plugin, eventName, testName, testElapsed)
            plugin.writeJson("active-test.json", plugin.payload(eventName, testName, testElapsed));
        end

        function payload = payload(plugin, eventName, testName, testElapsed)
            payload = struct( ...
                "timestamp", char(datetime("now", "TimeZone", "UTC", ...
                    "Format", "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")), ...
                "event", char(eventName), ...
                "test", char(testName), ...
                "started", plugin.Started, ...
                "completed", plugin.Completed, ...
                "total", plugin.Total, ...
                "suiteElapsedSeconds", plugin.suiteElapsed(), ...
                "testElapsedSeconds", double(testElapsed), ...
                "etaSeconds", plugin.etaSeconds());
        end

        function elapsed = suiteElapsed(plugin)
            if isempty(plugin.SuiteTimer)
                elapsed = 0;
            else
                elapsed = toc(plugin.SuiteTimer);
            end
        end

        function seconds = etaSeconds(plugin)
            if plugin.Completed == 0 || plugin.Completed >= plugin.Total
                seconds = NaN;
                return;
            end
            seconds = plugin.suiteElapsed() / plugin.Completed * ...
                (plugin.Total - plugin.Completed);
        end

        function text = etaText(plugin)
            seconds = plugin.etaSeconds();
            if isnan(seconds)
                text = "unknown";
            else
                text = string(sprintf("%.0fs", seconds));
            end
        end

        function appendJson(plugin, name, payload)
            plugin.write(name, payload, "a");
        end

        function writeJson(plugin, name, payload)
            plugin.write(name, payload, "w");
        end

        function write(plugin, name, payload, mode)
            file = fullfile(plugin.RunFolder, name);
            fid = fopen(file, mode, "n", "UTF-8");
            if fid < 0
                error("LabKit:TestRun:ArtifactWrite", ...
                    "Could not write test artifact: %s", file);
            end
            cleanup = onCleanup(@() fclose(fid));
            fprintf(fid, "%s\n", jsonencode(payload));
            clear cleanup
        end
    end
end
