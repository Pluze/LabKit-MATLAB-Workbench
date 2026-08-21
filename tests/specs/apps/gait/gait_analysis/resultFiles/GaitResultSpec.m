classdef GaitResultSpec < matlab.unittest.TestCase
    %GAITRESULTSPEC Specify the four-file gait CSV result set.

    methods (Test, TestTags = {'Contract:result', 'Env:headless'})
        function writesFrameCoordinateStepAndSummaryCsvFiles(testCase)
            result = GaitResultSpec.result();
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;

            outputs = gait_analysis.resultFiles.writeOutputs(folder, "gait", result);
            steps = readtable(outputs.stepCsv, "TextType", "string");

            testCase.verifyTrue(all(isfile([outputs.frameCsv; outputs.coordinateCsv; ...
                outputs.stepCsv; outputs.summaryCsv])));
            testCase.verifyTrue(any(string(steps.Properties.VariableNames) == "swing_time_s"));
            testCase.verifyEqual(height(steps), 2);
        end
    end

    methods (Static, Access = private)
        function result = result()
            pose = testfixtures.gait.pose();
            options = gait_analysis.analysisRun.defaultOptions();
            options.smoothWindow = 1;
            options.detectionProminence = 2;
            result = gait_analysis.analysisRun.computeGait(pose, options);
        end
    end
end
