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
        HeartbeatTimer = []
        HeartbeatSeconds = 30
    end

    methods
        function plugin = ProgressPlugin(runFolder, varargin)
            p = inputParser;
            p.addParameter("HeartbeatSeconds", 30, @isPositiveScalar);
            p.parse(varargin{:});
            plugin.RunFolder = string(runFolder);
            plugin.HeartbeatSeconds = double(p.Results.HeartbeatSeconds);
        end

        function delete(plugin)
            plugin.stopHeartbeat();
        end
    end

    methods (Access = protected)
        function runTestSuite(plugin, pluginData)
            plugin.Total = numel(pluginData.TestSuite);
            plugin.SuiteTimer = tic;
            plugin.record("suite_start", "", 0);
            plugin.writeActive("starting", "", 0);
            fprintf("LabKit test progress: 0/%d eta=unknown\n", plugin.Total);
            plugin.startHeartbeat();
            cleanup = onCleanup(@() plugin.stopHeartbeat());
            runTestSuite@matlab.unittest.plugins.TestRunnerPlugin(plugin, pluginData);
            plugin.record("suite_done", "", 0);
            plugin.writeActive("finished", "", 0);
            clear cleanup
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
        function startHeartbeat(plugin)
            plugin.stopHeartbeat();
            try
                plugin.HeartbeatTimer = timer( ...
                    "ExecutionMode", "fixedSpacing", ...
                    "Period", plugin.HeartbeatSeconds, ...
                    "BusyMode", "drop", ...
                    "TimerFcn", @(~, ~) plugin.heartbeat());
                start(plugin.HeartbeatTimer);
            catch
                plugin.HeartbeatTimer = [];
            end
        end

        function stopHeartbeat(plugin)
            timerObject = plugin.HeartbeatTimer;
            plugin.HeartbeatTimer = [];
            if isempty(timerObject)
                return;
            end
            try
                if isvalid(timerObject)
                    stop(timerObject);
                    delete(timerObject);
                end
            catch
            end
        end

        function heartbeat(plugin)
            if strlength(plugin.Current) == 0 || isempty(plugin.TestTimer)
                return;
            end
            elapsed = toc(plugin.TestTimer);
            plugin.record("heartbeat", plugin.Current, elapsed);
            plugin.writeActive("heartbeat", plugin.Current, elapsed);
            fprintf("HEARTBEAT [%d/%d eta=%s] %s\n", plugin.Started, ...
                plugin.Total, plugin.etaText(), plugin.Current);
        end

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

function tf = isPositiveScalar(value)
    tf = (isnumeric(value) || islogical(value)) && isscalar(value) && ...
        isfinite(double(value)) && double(value) > 0;
end
