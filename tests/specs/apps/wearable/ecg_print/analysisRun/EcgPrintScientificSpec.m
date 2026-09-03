classdef EcgPrintScientificSpec < matlab.unittest.TestCase
    %ECGPRINTSCIENTIFICSPEC Specify ECG analysis values independent of UI.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function sanitizesParametersAndMapsPeakMethodLabels(testCase)
            parameters = struct("roiStart", NaN, "roiEnd", Inf, ...
                "lowCut", -2, "highCut", 500, "peakDistance", 0, ...
                "peakLowCut", 60, "peakHighCut", 500, ...
                "useAnalysisBandForPeaks", false, ...
                "segmentWindow", NaN, "templateTopN", 2.6, "smoothBeats", Inf);

            actual = ecg_print.analysisRun.sanitizeParameters(parameters, 100);

            testCase.verifyEqual(actual.roiStart, 0);
            testCase.verifyEqual(actual.roiEnd, 0);
            testCase.verifyEqual(actual.lowCut, 0);
            testCase.verifyEqual(actual.highCut, 50);
            testCase.verifyLessThan(actual.peakLowCut, 50);
            testCase.verifyEqual(actual.peakHighCut, 50);
            testCase.verifyFalse(actual.useAnalysisBandForPeaks);
            testCase.verifyEqual(actual.templateTopN, 3);
            testCase.verifyEqual(actual.smoothBeats, 15);
            testCase.verifyEqual(ecg_print.analysisRun.peakMethodValue('Local peaks'), ...
                "local");
            testCase.verifyEqual(ecg_print.analysisRun.peakMethodValue('Pan-Tompkins'), ...
                "pan-tompkins");
            testCase.verifyEqual(ecg_print.analysisRun.peakMethodValue('QRS streaming'), ...
                "qrs-streaming");
            testCase.verifyError( ...
                @() ecg_print.analysisRun.peakMethodValue('unexpected'), ...
                'ecg_print:UnsupportedPeakMethodLabel');
        end

        function derivesGuiIndependentSignalProducts(testCase)
            fs = 100;
            time = (0:1/fs:6)';
            values = 0.02 .* sin(2 .* pi .* 1.5 .* time);
            values(101:100:501) = values(101:100:501) + 1;
            signal = struct("time", time, "values", values, "fs", fs, ...
                "displayName", "Synthetic ECG", "metadata", struct());
            cache = struct("signal", signal, "sourceMarker", 42);
            parameters = struct("lowCut", 0.5, "highCut", 40, "roiStart", 0, ...
                "roiEnd", 0, "peakMethod", "Local peaks", "peakDistance", 0.5, ...
                "segmentWindow", 0.7, "templateTopN", 5);

            actual = ecg_print.analysisRun.analyzeSignal(cache, parameters);

            testCase.verifyEqual(actual.sourceMarker, 42);
            testCase.verifyEqual(actual.workingSignal, signal);
            testCase.verifyEqual(actual.filteredSignal.metadata.filter.cutoffHz, [0.5 40]);
            testCase.verifyEqual(actual.events.metadata.method, "local");
            testCase.verifyEqual(actual.segments.metadata.windowSec, [-0.7 0.7]);
            testCase.verifyLessThanOrEqual(numel(actual.template.keptSegmentIndex), 5);
            testCase.verifyTrue(isfield(actual.measurements, 'perSegment'));
            testCase.verifyTrue(all([actual.powerSpectra.ok]));
            testCase.verifyEqual(actual.powerSpectra(3).title, ...
                "Peak-detection input · primary band reused");

            bypassParameters = parameters;
            bypassParameters.lowCut = 0;
            bypassParameters.highCut = fs / 2;
            bypassed = ecg_print.analysisRun.analyzeSignal( ...
                cache, bypassParameters);
            testCase.verifyEqual(bypassed.filteredSignal.values, signal.values);
            testCase.verifyEqual(bypassed.filteredSignal.metadata.filter.type, ...
                "none");

            parameters.useAnalysisBandForPeaks = false;
            parameters.peakLowCut = 5;
            parameters.peakHighCut = 20;
            detectedSeparately = ecg_print.analysisRun.analyzeSignal( ...
                cache, parameters);
            testCase.verifyEqual( ...
                detectedSeparately.peakDetectionSignal.metadata.filter.cutoffHz, ...
                [5 20]);
            expectedSegments = labkit.biosignal.segmentByEvents( ...
                detectedSeparately.filteredSignal, ...
                detectedSeparately.events, [-0.7 0.7]);
            testCase.verifyEqual(detectedSeparately.segments.values, ...
                expectedSegments.values, AbsTol=1e-12);
            testCase.verifyEqual(detectedSeparately.powerSpectra(3).title, ...
                "Peak-detection band output");
            testCase.verifyNotEqual( ...
                detectedSeparately.powerSpectra(2).powerDensity, ...
                detectedSeparately.powerSpectra(3).powerDensity);
        end

        function estimatesBoundedOneSidedWelchPowerDensity(testCase)
            sampleRate = 256;
            sampleCount = 16384;
            time = (0:sampleCount-1).' ./ sampleRate;
            amplitude = 2.5;
            frequencyHz = 16;
            values = amplitude .* sin(2 .* pi .* frequencyHz .* time);
            signal = struct("time", time, "values", values, ...
                "fs", sampleRate, "displayName", "Synthetic", ...
                "unit", "mV", "metadata", struct());
            cache = struct("workingSignal", signal, ...
                "filteredSignal", signal, "peakDetectionSignal", signal);

            models = ecg_print.analysisRun.powerSpectraModels(cache);

            raw = models(1);
            [~, dominantIndex] = max(raw.powerDensity);
            binWidth = raw.frequency(2) - raw.frequency(1);
            integratedPower = sum(raw.powerDensity) .* binWidth;
            testCase.verifyTrue(all([models.ok]));
            testCase.verifyEqual(raw.frequency(dominantIndex), ...
                frequencyHz, AbsTol=binWidth);
            testCase.verifyEqual(integratedPower, amplitude ^ 2 / 2, ...
                RelTol=0.01);
            testCase.verifyEqual(raw.segmentLength, 8192);
            testCase.verifyEqual(raw.segmentCount, 3);
            testCase.verifyEqual(raw.yLabel, ...
                "PSD (dB re 1 mV^2/Hz)");
            testCase.verifyEqual(models(3).title, ...
                "Peak-detection input · primary band reused");
            testCase.verifyEqual(models(3).powerDensity, ...
                models(2).powerDensity);
            testCase.verifyError(@() ...
                ecg_print.analysisRun.powerSpectraModels(cache, 1), ...
                "ecg_print:InvalidSpectrumStage");
        end

        function designsStableLinearPhaseFirAndCompensatesDelay(testCase)
            fs = 100;
            design = ecg_print.analysisRun.firDesign(fs, [5 20]);
            testCase.verifyFalse(design.bypass);
            testCase.verifyEqual(mod(numel(design.coefficients), 2), 1);
            testCase.verifyEqual(design.coefficients, ...
                flipud(design.coefficients), AbsTol=1e-14);
            testCase.verifyTrue(all(isfinite(design.coefficients)));
            testCase.verifyLessThan(sum(abs(design.coefficients)), 10);

            values = zeros(1001, 1);
            values(501) = 1;
            signal = struct("time", (0:1000).' / fs, "values", values, ...
                "fs", fs, "metadata", struct());
            filtered = ecg_print.analysisRun.applyFir(signal, design);
            [~, peakIndex] = max(abs(filtered.values));
            testCase.verifyEqual(peakIndex, 501);
            testCase.verifyEqual(filtered.metadata.filter.order, design.order);
            testCase.verifyTrue(filtered.metadata.filter.zeroPhaseAligned);

            bypass = ecg_print.analysisRun.firDesign(fs, [0 fs/2]);
            unchanged = ecg_print.analysisRun.applyFir(signal, bypass);
            testCase.verifyEqual(unchanged.values, signal.values);
            testCase.verifyEqual(unchanged.metadata.filter.type, "none");
        end

        function summarizesDetectedPeaksWithStableReaderFacingText(testCase)
            signal = struct("displayName", "Lead I", "values", [1 2 3 4], ...
                "fs", 250, "time", [0 .004 .008 .012], "unit", "mV");
            events = struct("index", [2 4], "metadata", struct("method", "qrs-streaming"));
            segments = struct("values", zeros(7, 2));
            measurements = struct("summary", struct( ...
                "SignalP2PMean", 1.234, "SignalP2PStd", .1234, ...
                "NoiseRMSMean", .05678, "NoiseRMSStd", .004321, ...
                "SNRdBMean", 12.345, "SNRdBStd", .9876, ...
                "TemplateCorrelationMean", .8765));

            rows = ecg_print.analysisRun.summaryRows(signal, events, segments, measurements);

            testCase.verifyEqual(rowValue(rows, 'Detected peaks'), '2 (qrs-streaming)');
            testCase.verifyEqual(rowValue(rows, 'Mean peak-to-peak (mV)'), '1.23');
            testCase.verifyEqual(rowValue(rows, 'Peak-to-peak std (mV)'), '0.123');
            testCase.verifyEqual(rowValue(rows, 'Mean noise RMS (mV)'), '0.0568');
            testCase.verifyEqual(rowValue(rows, 'Noise RMS std (mV)'), '0.00432');
            testCase.verifyEqual(rowValue(rows, 'Mean SNR (dB)'), '12.3');
            testCase.verifyEqual(rowValue(rows, 'SNR std (dB)'), '0.988');
            testCase.verifyEqual(ecg_print.analysisRun.signalUnit(signal), "mV");
            testCase.verifyEqual(ecg_print.analysisRun.signalUnit( ...
                rmfield(signal, "unit")), "ADC counts");
        end
    end
end

function value = rowValue(rows, name)
index = strcmp(rows(:, 1), name);
assert(nnz(index) == 1, "Missing summary row: %s.", name);
value = rows{index, 2};
end
