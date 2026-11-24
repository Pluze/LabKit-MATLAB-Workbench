classdef EmgReviewAnalysisSpec < matlab.unittest.TestCase
    methods (Test, TestTags={'Contract:scientific','Env:headless'})
        function measuresMeanRemovedRmsAndNoiseCorrectedSnr(testCase)
            % Analytic sine amplitudes give RMS A/sqrt(2), even with DC bias.
            fs = 256;
            time = (0:fs - 1).' / fs;
            baseline = 7 + 2*sin(2*pi*48*time);
            activity = -5 + 4*sin(2*pi*80*time);
            signal = makeSignal([baseline; activity; activity; baseline], fs);
            result = emg_review.analysisRun.measure(signal, "As recorded", [0 1; 3 2], 1);
            testCase.verifyEqual(result.metrics.BaselineRMS, [1; 1]*sqrt(2), AbsTol=1e-12);
            testCase.verifyEqual(result.metrics.ActivityRMS, [2; 2]*sqrt(2), AbsTol=1e-12);
            testCase.verifyEqual(result.metrics.SNR_dB, repmat(10*log10(3),2,1), AbsTol=1e-12);
            testCase.verifyEqual(result.metrics.Contrast_dB, repmat(20*log10(2),2,1), AbsTol=1e-12);
            [~, peaks] = max(result.density, [], 1);
            testCase.verifyEqual(result.frequency(peaks), [48;80]);
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

        function optionalBandpassKeeps10And480HzAndRejectsOutsideTones(testCase)
            fs = 2000;
            time = (0:3*fs - 1).' / fs;
            signal = makeSignal(sum(sin(2*pi*time .* [2 10 480 650]), 2), fs);
            [filtered, edge] = emg_review.analysisRun.prepare(signal, "5–500 Hz");
            % A one-second interval places the four test tones at exact FFT bins.
            amplitudes = 2*abs(fft(filtered(edge + (1:fs)))) / fs;
            testCase.verifyLessThan(amplitudes(2 + 1), 0.06);
            testCase.verifyEqual(amplitudes([10 480] + 1), [1; 1], AbsTol=0.002);
            testCase.verifyLessThan(amplitudes(650 + 1), 1e-4);
            result = emg_review.analysisRun.measure(signal, "5–500 Hz", [0.25 1.5], 1);
            testCase.verifyEqual(result.metrics.BaselineRMS, 1, AbsTol=0.002);
            testCase.verifyEqual(result.metrics.ActivityRMS, 1, AbsTol=0.002);
            testCase.verifyError(@() emg_review.analysisRun.measure( ...
                signal, "5–500 Hz", [0 1.5], 1), "emg_review:WindowOutsideRecording");
            lowerRate = makeSignal(signal.values(1:2:end), 1000);
            testCase.verifyError(@() emg_review.analysisRun.prepare( ...
                lowerRate, "5–500 Hz"), "emg_review:BelowNyquist");
        end
    end
end

function signal = makeSignal(values, fs)
    signal = struct('values', values, 'time', (0:numel(values) - 1).' / fs, 'fs', fs);
end
