classdef DicPostprocessScientificSpec < matlab.unittest.TestCase
    %DICPOSTPROCESSSCIENTIFICSPEC Specify DIC strain validity and overlays.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function summarizesFiniteStrainWithinItsScientificDomain(testCase)
            strain = struct( ...
                "exx", [1 2 NaN; NaN NaN NaN; 7 8 9], ...
                "eyy", [NaN 12 NaN; NaN 15 NaN; Inf 18 19], ...
                "roiMask", []);

            mask = dic_postprocess.analysisRun.summaryMaskForStrain(strain);
            summary = dic_postprocess.analysisRun.summarizeStrain(strain, mask);

            testCase.verifyEqual(mask, logical([1 1 0; 0 1 0; 1 1 1]));
            testCase.verifyEqual(summary.Metric, ...
                ["Mean"; "Std"; "Median"; "Min"; "Max"]);
            testCase.verifyEqual(summary.EXX([1 4 5]), [5.4; 1; 9], ...
                AbsTol=1e-12);
            testCase.verifyEqual(summary.EYY([1 4 5]), [16; 12; 19], ...
                AbsTol=1e-12);
        end

        function trimsOnlyTheFiniteRoiBoundaryUnlessDisabled(testCase)
            strain = ones(5);
            strain([1 end], :) = -10;
            strain(:, [1 end]) = -10;

            trimmed = dic_postprocess.analysisRun.strainValidMask( ...
                strain, true(5), true(5));
            untrimmed = dic_postprocess.analysisRun.strainValidMask( ...
                strain, true(5), true(5), 0);

            expected = false(5);
            expected(2:4, 2:4) = true;
            testCase.verifyEqual(trimmed, expected);
            testCase.verifyEqual(untrimmed, true(5));
        end

        function buildsBoundedOverlaysAndSupportsEmptyDomains(testCase)
            reference = uint8(128 * ones(5));
            strain = ones(5);
            strain([1 end], :) = 0;
            strain(:, [1 end]) = 0;
            options = overlayOptions();
            options.alpha = 1;
            options.colormap = [0 0 1; 1 0 0];

            trimmed = dic_postprocess.analysisRun.makeStrainOverlay( ...
                reference, strain, true(5), true(5), options);
            options.edgeTrim = 0;
            full = dic_postprocess.analysisRun.makeStrainOverlay( ...
                reference, strain, true(5), true(5), options);
            empty = dic_postprocess.analysisRun.extendStrainMapToRoi( ...
                [1 2; 3 4], false(2));

            base = double(reference(1, 1)) / 255;
            testCase.verifyEqual(squeeze(trimmed(1, 1, :)).', [base base base], ...
                AbsTol=1e-12);
            testCase.verifyEqual(squeeze(full(1, 1, :)).', [0 0 1], AbsTol=1e-12);
            testCase.verifySize(full, [5 5 3]);
            testCase.verifyTrue(all(full >= 0 & full <= 1, "all"));
            testCase.verifyTrue(all(isnan(empty), "all"));
        end

        function preparesBothStrainOutputsFromOneInputContract(testCase)
            inputs = struct( ...
                "referenceImage", zeros(16, 16, 3), ...
                "maskImage", true(16), ...
                "strain", struct("exx", zeros(8), "eyy", 0.01 .* ones(8), ...
                    "roiMask", true(8)));

            [summary, exx, eyy] = dic_postprocess.analysisRun.prepareOutputs( ...
                inputs, projectParameters());

            testCase.verifyEqual(summary.Metric, ...
                ["Mean"; "Std"; "Median"; "Min"; "Max"]);
            testCase.verifySize(exx, [16 16 3]);
            testCase.verifySize(eyy, [16 16 3]);
        end
    end
end

function options = overlayOptions()
options = struct("alpha", 0.5, "colorRange", [0 1], "oversample", 1, ...
    "sigmaSmooth", 0, "edgeTrim", 1, "colormap", [0 0 1; 1 0 0], ...
    "brightness", 0, "contrast", 1, "gamma", 1, "saturation", 1, ...
    "rgbGain", [1 1 1]);
end

function parameters = projectParameters()
parameters = struct("alpha", 0.60, "colorMin", -0.15, "colorMax", 0.15, ...
    "oversample", 6, "smoothSigma", 0.8, "edgeTrim", 1, "brightness", 0, ...
    "contrast", 1, "gamma", 1, "saturation", 1, "redGain", 1, ...
    "greenGain", 1, "blueGain", 1);
end
