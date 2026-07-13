classdef DicPostprocessOpsTest < matlab.unittest.TestCase
    %DICPOSTPROCESSOPSTEST Verify GUI-free DIC postprocess ops helpers.

    methods (Test, TestTags = {'Unit'})
        function maskAndSizeHelpersMatchImageInputs(testCase)
            setupLabKitTestPath();

            imageData = zeros(3, 4, 3, 'uint8');
            maskImage = uint8([0 129; 128 255]);

            testCase.verifyEqual(dic_postprocess.analysisRun.imageHeightWidth(imageData), [3 4]);
            testCase.verifyEqual(dic_postprocess.analysisRun.imageMask(maskImage, [2 2]), ...
                logical([0 1; 0 1]));
        end

        function summaryMaskPrefersRoiMask(testCase)
            setupLabKitTestPath();

            strain = struct();
            strain.exx = [1 2; NaN 4];
            strain.eyy = [5 Inf; 7 8];
            strain.roiMask = logical([1 0; 0 1]);

            mask = dic_postprocess.analysisRun.summaryMaskForStrain(strain);

            testCase.verifyEqual(mask, strain.roiMask);
        end

        function strainValidMaskTrimsFiniteRoiBoundary(testCase)
            setupLabKitTestPath();

            strainMap = ones(5);
            strainMap([1 end], :) = -10;
            strainMap(:, [1 end]) = -10;
            roiMask = true(5);

            validMap = dic_postprocess.analysisRun.strainValidMask( ...
                strainMap, roiMask, true(5));

            expected = false(5);
            expected(2:4, 2:4) = true;
            testCase.verifyEqual(validMap, expected);
        end

        function strainValidMaskKeepsNarrowRoiWhenTrimWouldErase(testCase)
            setupLabKitTestPath();

            validMap = dic_postprocess.analysisRun.strainValidMask( ...
                ones(2), true(2), true(2));

            testCase.verifyEqual(validMap, true(2));
        end

        function edgeTrimCanBeDisabledForFullRoiCoverage(testCase)
            setupLabKitTestPath();

            validMap = dic_postprocess.analysisRun.strainValidMask( ...
                ones(5), true(5), true(5), 0);

            testCase.verifyEqual(validMap, true(5));
        end

        function summaryMaskUsesMatFiniteDomainWhenRoiAbsent(testCase)
            setupLabKitTestPath();

            strain = struct();
            strain.exx = [1 2 NaN; NaN NaN NaN; 7 8 9];
            strain.eyy = [NaN 12 NaN; NaN 15 NaN; Inf 18 19];
            strain.roiMask = [];

            mask = dic_postprocess.analysisRun.summaryMaskForStrain(strain);
            summary = dic_postprocess.analysisRun.summarizeStrain(strain, mask);

            expected = logical([1 1 0; 0 1 0; 1 1 1]);
            testCase.verifyEqual(mask, expected);
            testCase.verifyEqual(summary.EXX([1 4 5]), [5.4; 1; 9], ...
                'AbsTol', 1e-12);
            testCase.verifyEqual(summary.EYY([1 4 5]), [16; 12; 19], ...
                'AbsTol', 1e-12);
        end

        function summarizeStrainIgnoresInvalidValues(testCase)
            setupLabKitTestPath();

            strain = struct();
            strain.exx = [1 2; NaN 4];
            strain.eyy = [10 Inf; 20 30];
            mask = true(2);

            T = dic_postprocess.analysisRun.summarizeStrain(strain, mask);

            testCase.verifyEqual(T.Metric, ["Mean"; "Std"; "Median"; "Min"; "Max"]);
            testCase.verifyEqual(T.EXX([1 3 4 5]), [7/3; 2; 1; 4], 'AbsTol', 1e-12);
            testCase.verifyEqual(T.EYY([1 3 4 5]), [20; 20; 10; 30], 'AbsTol', 1e-12);
        end

        function overlayPipelinePreservesShapeAndRange(testCase)
            setupLabKitTestPath();

            reference = uint8([0 64; 128 255]);
            strainMap = [0 1; 0.25 0.5];
            displayMask = true(2);
            opts = postprocessOverlayOptions();

            overlay = dic_postprocess.analysisRun.makeStrainOverlay( ...
                reference, strainMap, displayMask, [], opts);

            testCase.verifySize(overlay, [2 2 3]);
            testCase.verifyGreaterThanOrEqual(overlay, 0);
            testCase.verifyLessThanOrEqual(overlay, 1);
        end

        function overlayExcludesFiniteLowValueRoiBoundary(testCase)
            setupLabKitTestPath();

            reference = uint8(128 * ones(5));
            strainMap = ones(5);
            strainMap([1 end], :) = 0;
            strainMap(:, [1 end]) = 0;
            opts = postprocessOverlayOptions();
            opts.alpha = 1;
            opts.colormap = [0 0 1; 1 0 0];

            overlay = dic_postprocess.analysisRun.makeStrainOverlay( ...
                reference, strainMap, true(5), true(5), opts);

            basePixel = double(reference(1, 1)) / 255;
            testCase.verifyEqual(squeeze(overlay(1, 1, :)).', ...
                [basePixel basePixel basePixel], 'AbsTol', 1e-12);
            testCase.verifyEqual(squeeze(overlay(3, 3, :)).', ...
                [1 0 0], 'AbsTol', 1e-12);
        end

        function overlayCanCoverFullRoiWhenEdgeTrimDisabled(testCase)
            setupLabKitTestPath();

            reference = uint8(128 * ones(5));
            strainMap = ones(5);
            strainMap([1 end], :) = 0;
            strainMap(:, [1 end]) = 0;
            opts = postprocessOverlayOptions();
            opts.alpha = 1;
            opts.edgeTrim = 0;
            opts.colormap = [0 0 1; 1 0 0];

            overlay = dic_postprocess.analysisRun.makeStrainOverlay( ...
                reference, strainMap, true(5), true(5), opts);

            testCase.verifyEqual(squeeze(overlay(1, 1, :)).', ...
                [0 0 1], 'AbsTol', 1e-12);
            testCase.verifyEqual(squeeze(overlay(3, 3, :)).', ...
                [1 0 0], 'AbsTol', 1e-12);
        end

        function overlayPipelineSupportsSmoothingAndOversampleWithoutToolboxes(testCase)
            setupLabKitTestPath();

            reference = uint8(repmat(reshape(1:16, 4, 4), [1 1 3]));
            strainMap = reshape(linspace(-0.1, 0.1, 16), 4, 4);
            opts = postprocessOverlayOptions();
            opts.alpha = 0.75;
            opts.colorRange = [-0.1 0.1];
            opts.sigmaSmooth = 0.8;
            opts.oversample = 3;
            opts.edgeTrim = 0;

            overlay = dic_postprocess.analysisRun.makeStrainOverlay( ...
                reference, strainMap, true(6), true(4), opts);

            testCase.verifySize(overlay, [4 4 3]);
            testCase.verifyClass(overlay, 'double');
            testCase.verifyTrue(all(isfinite(overlay), 'all'));
            testCase.verifyGreaterThan(max(overlay, [], 'all'), ...
                min(overlay, [], 'all'));
        end

        function extendStrainMapHandlesEmptyValidMap(testCase)
            setupLabKitTestPath();

            filled = dic_postprocess.analysisRun.extendStrainMapToRoi([1 2; 3 4], false(2));

            testCase.verifyTrue(all(isnan(filled), 'all'));
        end
    end
end

function opts = postprocessOverlayOptions()
    opts = struct();
    opts.alpha = 0.5;
    opts.colorRange = [0 1];
    opts.oversample = 1;
    opts.sigmaSmooth = 0;
    opts.edgeTrim = 1;
    opts.colormap = [0 0 1; 1 0 0];
    opts.brightness = 0;
    opts.contrast = 1;
    opts.gamma = 1;
    opts.saturation = 1;
    opts.rgbGain = [1 1 1];
end
