classdef EmgReviewAnalysisSpec < matlab.unittest.TestCase
    methods (Test, TestTags={'Contract:scientific','Env:headless'})
        function measuresMeanRemovedRmsAndNoiseCorrectedSnr(testCase)
            % Analytic sine amplitudes give RMS A/sqrt(2), even with DC bias.
            fs = 256;
            time = (0:fs - 1).' / fs;
            baseline = 7 + 2*sin(2*pi*60*time);
            activity = -5 + 4*sin(2*pi*80*time);
            signal = makeSignal([baseline; activity; activity; baseline], fs);
            result = emg_review.analysisRun.measure(signal, "As recorded", [0 1; 3 2], 1);
            testCase.verifyEqual(result.metrics.BaselineRMS, [1; 1]*sqrt(2), AbsTol=1e-12);
            testCase.verifyEqual(result.metrics.ActivityRMS, [2; 2]*sqrt(2), AbsTol=1e-12);
            testCase.verifyEqual(result.metrics.SNR_dB, repmat(10*log10(3),2,1), AbsTol=1e-12);
            testCase.verifyEqual(result.metrics.Contrast_dB, repmat(20*log10(2),2,1), AbsTol=1e-12);
            testCase.verifyEqual(result.metrics.BaselineLinePower_pct, [100;100], AbsTol=1e-10);
            testCase.verifyEqual(result.metrics.ActivityLinePower_pct, [0;0], AbsTol=1e-10);
            [~, peaks] = max(result.density, [], 1);
            testCase.verifyEqual(result.frequency(peaks), [60;80]);
            testCase.verifyEqual(sum(result.density, 1), [2 8], AbsTol=1e-12);
            image = result.spectrogram;
            [~, index] = min(abs(image.time - 1.5));
            [~, peak] = max(image.density(:, index));
            testCase.verifyEqual(image.frequency(peak), 80);
        end

        function retainsUndefinedSnrAndRejectsInvalidWindows(testCase)
            signal = makeSignal(repmat([1;-1], 8, 1), 8);
            result = emg_review.analysisRun.measure(signal, "As recorded", [0 1], 1);
            testCase.verifyTrue(isnan(result.metrics.SNR_dB));
            testCase.verifyEqual(result.metrics.Contrast_dB, 0);
            testCase.verifyError(@() emg_review.analysisRun.measure( ...
                signal, "As recorded", [0 0.5], 1), "emg_review:OverlappingWindows");
            testCase.verifyError(@() emg_review.analysisRun.measure( ...
                signal, "As recorded", [0 1.1], 1), "emg_review:WindowOutsideRecording");
        end

        function bandpassKeepsInBandToneAndExcludesReferenceEdges(testCase)
            fs = 2000;
            time = (0:3*fs - 1).' / fs;
            signal = makeSignal(sin(2*pi*100*time) + sin(2*pi*650*time), fs);
            result = emg_review.analysisRun.measure(signal, "20–450 Hz", [0.25 1.5], 1);
            testCase.verifyEqual(result.metrics.BaselineRMS, sqrt(0.5), AbsTol=1e-4);
            testCase.verifyEqual(result.metrics.ActivityRMS, sqrt(0.5), AbsTol=1e-4);
            testCase.verifyError(@() emg_review.analysisRun.measure( ...
                signal, "20–450 Hz", [0 1.5], 1), "emg_review:WindowOutsideRecording");
        end
    end
end

function signal = makeSignal(values, fs)
    signal = struct('values', values, 'time', (0:numel(values) - 1).' / fs, 'fs', fs);
end
