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

        function usesOneReadableUnitForAWindow(testCase)
            display = ni_dmm_recorder.workbench.displayMeasurement( ...
                [0, -2.3e-6, NaN], "A");
            testCase.verifyEqual(display.divisor, 1e-6);
            testCase.verifyEqual(display.unit, "uA");
            testCase.verifyEqual(-2.3e-6 / display.divisor, -2.3, ...
                "AbsTol", 1e-12);

            display = ni_dmm_recorder.workbench.displayMeasurement( ...
                [150, 2300], "ohm");
            testCase.verifyEqual(display.divisor, 1e3);
            testCase.verifyEqual(display.unit, "k" + ...
                string(char(hex2dec("03A9"))));

            display = ni_dmm_recorder.workbench.displayMeasurement( ...
                [0, NaN], "V");
            testCase.verifyEqual(display.divisor, 1);
            testCase.verifyEqual(display.unit, "V");

            display = ni_dmm_recorder.workbench.displayMeasurement( ...
                2e-6, "counts");
            testCase.verifyEqual(display.divisor, 1);
            testCase.verifyEqual(display.unit, "counts");
        end
    end
end
