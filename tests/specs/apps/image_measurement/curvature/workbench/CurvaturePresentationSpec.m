classdef CurvaturePresentationSpec < matlab.unittest.TestCase
    %CURVATUREPRESENTATIONSPEC Specify initial curve measurement readouts.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function presentsTheStableInitialMetricRows(testCase)
            rows = curvature.curvePreview.presentationData.initialResultTable();

            testCase.verifyTrue(iscell(rows));
            testCase.verifyEqual(rows{1, 1}, 'Curve length');
            testCase.verifyEqual(rows{end, 1}, 'Pixels/unit');
        end
    end
end
