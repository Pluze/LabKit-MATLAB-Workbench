classdef EcgPrintPresentationSpec < matlab.unittest.TestCase
    %ECGPRINTPRESENTATIONSPEC Specify request models for ECG renderers.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function buildsWaveformPeaksAndTemplateResidualModels(testCase)
            working = struct("time", [0 1 2 3], "values", [10 11 12 13], ...
                "name", "raw", "displayName", "ECG", "unit", "mV", "fs", 4);
            filtered = struct("time", [0 1 2 3], "values", [1 3 2 4], ...
                "name", "filtered", "displayName", "ECG", "unit", "mV");
            events = struct("index", [2 4]);
            segments = struct("values", [1 2 3; 2 4 6; 3 6 9], ...
                "timeOffset", [-.1 0 .1]);
            template = struct("values", [2; 4; 6]);
            measurements = struct("metadata", struct("signalWindowSec", [-.04 .04], ...
                "noiseWindowsSec", [-.2 -.1; .1 .2]));

            waveform = ecg_print.analysisRun.waveformPlotRequest( ...
                working, filtered, events, "recording.csv");
            templateRequests = ecg_print.analysisRun.templatePlotRequests( ...
                segments, template, measurements, "mV");
            cache = struct("signal", working, "filteredSignal", filtered, ...
                "peakDetectionSignal", filtered);
            parameters = ecg_print.initialData().parameters;
            filterModel = ecg_print.analysisRun.filterDetailsModel( ...
                cache, parameters);

            testCase.verifyTrue(waveform.ok);
            testCase.verifyEqual(waveform.peakX, [1 3]);
            testCase.verifyEqual(waveform.peakY, [3 4]);
            testCase.verifyEqual(waveform.title, 'recording.csv');
            testCase.verifyEqual(waveform.yLabel, 'ECG (mV)');
            testCase.verifyTrue(all([templateRequests.ok]));
            testCase.verifyFalse(templateRequests(1).showSegments);
            testCase.verifyTrue(templateRequests(2).showSegments);
            testCase.verifyEqual(templateRequests(1).signalWindowSec, [-.04 .04]);
            testCase.verifyEqual(templateRequests(1).upper - templateRequests(1).template, ...
                std(segments.values - template.values, 0, 2, 'omitnan'), AbsTol=1e-12);
            testCase.verifyEqual(templateRequests(2).showIndex, 1:3);
            testCase.verifyEqual(templateRequests(1).yLabel, 'Amplitude (mV)');
            testCase.verifyTrue(filterModel.ok);
            testCase.verifyEqual(filterModel.analysisBand, [0 2]);
            testCase.verifyEmpty(filterModel.second.magnitudeDb);
            testCase.verifyEqual(filterModel.cascade.magnitudeDb, ...
                filterModel.first.magnitudeDb);
            testCase.verifySize(filterModel.first.phase, ...
                size(filterModel.frequency));
            testCase.verifySize(filterModel.first.groupDelay, ...
                size(filterModel.frequency));
            testCase.verifySize(filterModel.first.impulse, ...
                size(filterModel.first.impulseTime));
            parameters.useAnalysisBandForPeaks = false;
            parameters.peakLowCut = 1;
            parameters.peakHighCut = 1.5;
            secondaryModel = ecg_print.analysisRun.filterDetailsModel( ...
                cache, parameters);
            testCase.verifyNotEmpty(secondaryModel.second.magnitudeDb);
            passIndex = nearestIndex(secondaryModel.frequency, 1.25);
            stopIndex = nearestIndex(secondaryModel.frequency, 1.75);
            testCase.verifyGreaterThan( ...
                secondaryModel.cascade.magnitudeDb(passIndex), -1);
            testCase.verifyLessThan( ...
                secondaryModel.cascade.magnitudeDb(stopIndex), -20);
            testCase.verifyTrue(isfinite( ...
                secondaryModel.cascade.phase(passIndex)));
            expectedDelay = 0.5 * (secondaryModel.cascade.tapCount - 1);
            testCase.verifyEqual( ...
                secondaryModel.cascade.groupDelay(passIndex), ...
                expectedDelay, AbsTol=1e-8);
        end
    end
end

function index = nearestIndex(values, target)
[~, index] = min(abs(values - target));
end
