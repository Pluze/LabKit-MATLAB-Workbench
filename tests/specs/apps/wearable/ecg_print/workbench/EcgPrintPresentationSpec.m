classdef EcgPrintPresentationSpec < matlab.unittest.TestCase
    %ECGPRINTPRESENTATIONSPEC Specify request models for ECG renderers.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function buildsWaveformPeaksAndTemplateResidualModels(testCase)
            working = struct("time", [0 1 2 3], "values", [10 11 12 13], "name", "raw");
            filtered = struct("time", [0 1 2 3], "values", [1 3 2 4], "name", "filtered");
            events = struct("index", [2 4]);
            segments = struct("values", [1 2 3; 2 4 6; 3 6 9], ...
                "timeOffset", [-.1 0 .1]);
            template = struct("values", [2; 4; 6]);
            measurements = struct("metadata", struct("signalWindowSec", [-.04 .04], ...
                "noiseWindowsSec", [-.2 -.1; .1 .2]));

            waveform = ecg_print.analysisRun.waveformPlotRequest(working, filtered, events);
            templateRequest = ecg_print.analysisRun.templatePlotRequest( ...
                segments, template, measurements, 'Template + residual band');

            testCase.verifyTrue(waveform.ok);
            testCase.verifyEqual(waveform.peakX, [1 3]);
            testCase.verifyEqual(waveform.peakY, [3 4]);
            testCase.verifyTrue(templateRequest.ok);
            testCase.verifyFalse(templateRequest.showSegments);
            testCase.verifyEqual(templateRequest.signalWindowSec, [-.04 .04]);
            testCase.verifyEqual(templateRequest.upper - templateRequest.template, ...
                std(segments.values - template.values, 0, 2, 'omitnan'), AbsTol=1e-12);
        end
    end
end
