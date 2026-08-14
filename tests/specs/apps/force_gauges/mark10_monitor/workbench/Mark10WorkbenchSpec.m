classdef Mark10WorkbenchSpec < matlab.unittest.TestCase
    %MARK10WORKBENCHSPEC Specify the complete reader-facing monitor workflow.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function declaresMonitorSettingsExportAndReplayControls(testCase)
            plan = labkittest.inspectDefinition(mark10_monitor.definition());
            ids = string({plan.Nodes.Id});

            testCase.verifyTrue(all(ismember([ ...
                "serialPort", "startRecording", "zeroForce", "livePlots", ...
                "applySettings", "exportRecording", "openRecording", ...
                "resetRecording", "playRecording", "pauseRecording", ...
                "refitLiveAxes", "refitReplayAxes", "recentData"], ids)));

            statusIds = ["connectionStatus", "acquisitionStatus", ...
                "liveReadout", "exportStatus", "playbackStatus", ...
                "settingsStatus", "deviceIdentity", ...
                "deviceCapabilities", "lastFailure"];
            for statusId = statusIds
                node = plan.Nodes(ids == statusId);
                testCase.verifyEqual(node.Kind, "statusPanel", ...
                    "Status text must use compact framework status cards.");
            end

            plots = plan.Nodes(ids == "livePlots");
            testCase.verifyEqual(plots.AxisIds, ...
                ["timeSeries", "forceTravel"]);
        end
    end
end
