classdef CicPresentationSpec < matlab.unittest.TestCase
    %CICPRESENTATIONSPEC Verify CIC presentation values without GUI traversal.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function summarizesComputedAnalysisForTheWorkbench(testCase)
            item = testfixtures.dta.chronoItem('', 'sample.DTA');
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

        function normalizesDisplayUnitsAndKeepsFallbackLabels(testCase)
            [microScale, microLabel, microSuffix] = cic.analysisRun.displayUnit("uC/cm^2");
            [fallbackScale, fallbackLabel, fallbackSuffix] = cic.analysisRun.displayUnit("unexpected");

            testCase.verifyEqual(microScale, 1e3);
            testCase.verifyEqual(string({microLabel, microSuffix}), ["uC/cm^2", "uCcm2"]);
            testCase.verifyEqual(fallbackScale, 1);
            testCase.verifyEqual(string({fallbackLabel, fallbackSuffix}), ["mC/cm^2", "mCcm2"]);
        end

        function reportsFailedCurrentAnalysisAndNoSafeBatchValue(testCase)
            item = testfixtures.dta.chronoItem('', "failed.DTA");
            item.controlMode = "unknown";
            item.analysis = struct("ok", false, "message", "bad pulse window");
            choices = cic.analysisRun.analysisChoices();

            summary = cic.analysisRun.buildCurrentSummary(item, 1, ...
                choices.cicModes(3), "mC/cm^2");

            testCase.verifyEqual(string(summary.controlMode), "Unknown chrono control mode");
            testCase.verifyEqual(string({summary.detect, summary.delay, summary.qc}), ["-", "-", "-"]);
            testCase.verifyEqual(string(summary.safe), "bad pulse window");
            testCase.verifyEqual(string(summary.bestSafe), "No safe file in current batch");
        end

        function buildsAStableTimeVoltagePlotRequest(testCase)
            item = testfixtures.dta.chronoItem('', "sample.DTA");
            item.analysis = cic.analysisRun.computeCIC(item, defaultOptions());
            choices = cic.analysisRun.analysisChoices();

            request = cic.analysisPlot.plotRequest(item.analysis, item.name, ...
                choices.xAxes(1), choices.yAxes(1));

            testCase.verifyEqual(string(request.kind), "VT");
            testCase.verifyEqual(request.x, item.analysis.t);
            testCase.verifyEqual(request.y, item.analysis.Vf);
            testCase.verifyEqual(string(request.xLabel), choices.xAxes(1));
            testCase.verifyEqual(string(request.yLabel), "Vf (V vs Ref.)");
            testCase.verifyEqual(request.coords.cathStartX, item.analysis.pulse.cath.start_s);
            testCase.verifyEqual(request.coords.anodEndX, item.analysis.pulse.anod.end_s);
        end
    end
end

function options = defaultOptions()
    choices = cic.analysisRun.analysisChoices();
    options = struct('delay_s', 10e-6, 'cathLimit', -0.6, 'anodLimit', 0.8, ...
        'areaOverride', '', 'pulseMode', char(choices.pulseModes(1)), ...
        'usedMeasuredCurrent', true);
end
