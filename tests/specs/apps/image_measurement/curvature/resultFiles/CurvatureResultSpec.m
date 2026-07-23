classdef CurvatureResultSpec < matlab.unittest.TestCase
    %CURVATURERESULTSPEC Specify curvature export units and stable columns.

    methods (Test, TestTags = {'Contract:result', 'Env:headless'})
        function exportsFittedRadiusCurvatureAndCurveLengthTogether(testCase)
            theta = linspace(0, .5 .* pi, 6)';
            fit = curvature.analysisRun.computeFitFromOptions(12 + 30 .* cos(theta), ...
                22 + 30 .* sin(theta), struct("referencePx", 15, ...
                "referenceLength", 1, "scaleUnit", "mm", "doDensify", false));

            result = curvature.resultFiles.buildResultTable(fit, "sample.png");

            testCase.verifyEqual(result.Image, "sample.png");
            testCase.verifyEqual(result.Radius_px, fit.R_px);
            testCase.verifyEqual(result.Curvature, fit.kappa_show);
            testCase.verifyEqual(result.ReferenceUnit, "mm");
            testCase.verifyEqual(result.CurveLength_px, fit.curveLength_px);
        end
    end
end
