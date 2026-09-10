classdef NIDmmWorkbenchSpec < matlab.unittest.TestCase
    % NIDMMWORKBENCHSPEC Invariant: workbench controls and presentation expose the complete recording state safely.

    methods (Test, TestTags = {'Contract:presentation', 'Env:'})
        function provesNIDmmWorkbench(testCase)
            plan = labkittest.inspectDefinition(ni_dmm_recorder.definition());
            ids = string({plan.Nodes.Id});
            testCase.verifyTrue(all(ismember(["resourceName", "checkDriver", ...
                "connectDevice", "measurementMode", "rangeMode", ...
                "fixedRange", "resolutionDigits", "sampleRate", "readOnce", ...
                "startRecording", "stopRecording", "measurementPlot", ...
                "recentData", "exportRecording"], ids)));
            state = ni_dmm_recorder.createSession( ...
                labkittest.createCallbackContext(struct("setResource", ...
                @(~, ~, ~) [])), struct());
            view = ni_dmm_recorder.workbench.present(state);
            testCase.verifyClass(view, "labkit.app.view.Snapshot");
        end
    end
end
