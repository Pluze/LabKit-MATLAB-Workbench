classdef NIDmmWorkbenchSpec < matlab.unittest.TestCase
    % NIDMMWORKBENCHSPEC Invariant: workbench controls and presentation expose the complete recording state safely.

    methods (Test, TestTags = {'Contract:presentation', 'Env:'})
        function provesNIDmmWorkbench(testCase)
            plan = labkittest.inspectDefinition(ni_dmm_recorder.definition());
            ids = string({plan.Nodes.Id});
            testCase.verifyTrue(all(ismember(["resourceName", "refreshDevices", ...
                "connectDevice", "measurementMode", "rangeMode", ...
                "fixedRange", "resolutionDigits", "sampleRate", "readOnce", ...
                "startRecording", "stopRecording", "measurementPlot", ...
                "recentData", "exportRecording"], ids)));
            state = ni_dmm_recorder.createSession( ...
                labkittest.createCallbackContext(struct("setResource", ...
                @(~, ~, ~) [])), struct());
            view = ni_dmm_recorder.workbench.present(state);
            testCase.verifyClass(view, "labkit.app.view.Snapshot");

            state.session.acquisition.recording = false;
            state.session.acquisition.unit = "ohm";
            state.session.acquisition.plotTime_s = [0.1, 0.2, 0.3];
            state.session.acquisition.plotValue = [100, 101, 102];
            state.session.acquisition.plotTimestampUTC = datetime( ...
                2026, 1, 1, 0, 0, [0.1, 0.2, 0.3], TimeZone="UTC");
            view = ni_dmm_recorder.workbench.present(state);
            testCase.verifyClass(view, "labkit.app.view.Snapshot");
        end
    end
end
