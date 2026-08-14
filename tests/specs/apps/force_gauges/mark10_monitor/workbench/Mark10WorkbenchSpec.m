classdef Mark10WorkbenchSpec < matlab.unittest.TestCase
    %MARK10WORKBENCHSPEC Specify the complete reader-facing monitor workflow.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function declaresMonitorSettingsExportAndReplayControls(testCase)
            plan = labkittest.inspectDefinition(mark10_monitor.definition());
            ids = string({plan.Nodes.Id});

            testCase.verifyTrue(all(ismember([ ...
                "serialPort", "startRecording", "zeroForce", "livePlots", ...
                "applySettings", "exportRecording", "openRecording", ...
                "playRecording", "pauseRecording", "recentData"], ids)));
        end
    end
end
