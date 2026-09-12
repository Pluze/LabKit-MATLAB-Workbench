classdef NIDmmLivePlotSpec < matlab.unittest.TestCase
    %NIDMMLIVEPLOTSPEC Specify empty and measured recorder plot rendering.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function rendersEmptyAndMeasuredModels(testCase)
            figureHandle = figure("Visible", "off");
            cleanup = onCleanup(@() close(figureHandle));
            axesHandle = axes(figureHandle);
            axesById = struct("measurement", axesHandle);
            ni_dmm_recorder.livePlot.draw(axesById, struct( ...
                "Time_s", zeros(0, 1), "Value", zeros(0, 1), ...
                "Unit", "ohm"));
            testCase.verifyNumElements(findall(axesHandle, "Type", "text"), 1);

            ni_dmm_recorder.livePlot.draw(axesById, struct( ...
                "Time_s", [0; 0.02; 0.04], ...
                "Value", [200; 201; 202], "Unit", "ohm"));
            lines = findall(axesHandle, "Type", "line");
            testCase.verifyNumElements(lines, 1);
            testCase.verifyEqual(lines.YData, [200, 201, 202]);
            testCase.verifyEqual(string(axesHandle.YLabel.String), ...
                "Measurement (ohm)");

            ni_dmm_recorder.livePlot.draw(axesById, struct( ...
                "Time_s", [0; 0.02; 0.04], ...
                "Value", [2.1; 2.2; 2.3], "Unit", "uA"));
            lines = findall(axesHandle, "Type", "line");
            testCase.verifyEqual(lines.YData, [2.1, 2.2, 2.3]);
            testCase.verifyEqual(string(axesHandle.YLabel.String), ...
                "Measurement (uA)");
            clear cleanup
        end
    end
end
