classdef CicPresentationSpec < matlab.unittest.TestCase
    %CICPRESENTATIONSPEC Verify CIC presentation values without GUI traversal.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function summarizesComputedAnalysisForTheWorkbench(testCase)
            item = makeChronoFixtureItem('', 'sample.DTA');
            item.analysis = cic.analysisRun.computeCIC(item, defaultOptions());
            choices = cic.analysisRun.analysisChoices();

            summary = cic.analysisRun.buildCurrentSummary( ...
                item, 1, choices.cicModes(1), 'mC/cm^2');

            testCase.verifyEqual(summary.controlMode, 'Unknown chrono control mode');
            testCase.verifyTrue(startsWith(string(summary.detect), ...
                "metadata-current | "));
            testCase.verifyEqual(summary.delay, '10.000 us');
            testCase.verifyEqual(summary.safe, ...
                'UNSAFE | Emc>=-0.600? 0 | Ema<=0.800? 0');
        end
    end
end

function options = defaultOptions()
    choices = cic.analysisRun.analysisChoices();
    options = struct('delay_s', 10e-6, 'cathLimit', -0.6, 'anodLimit', 0.8, ...
        'areaOverride', '', 'pulseMode', char(choices.pulseModes(1)), ...
        'usedMeasuredCurrent', true);
end
