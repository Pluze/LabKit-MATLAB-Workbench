classdef DicPostprocessOpsTest < matlab.unittest.TestCase
    %DICPOSTPROCESSOPSTEST Verify GUI-free DIC postprocess ops helpers.

    methods (Test, TestTags = {'Unit'})
        function maskAndSizeHelpersMatchImageInputs(testCase)
            setupLabKitTestPath();

            imageData = zeros(3, 4, 3, 'uint8');
            maskImage = uint8([0 129; 128 255]);

            testCase.verifyEqual(dic_postprocess.ops.imageHeightWidth(imageData), [3 4]);
            testCase.verifyEqual(dic_postprocess.ops.imageMask(maskImage, [2 2]), ...
                logical([0 1; 0 1]));
        end

        function summaryMaskPrefersRoiMask(testCase)
            setupLabKitTestPath();

            strain = struct();
            strain.exx = ones(2);
            strain.eyy = ones(2);
            strain.roiMask = logical([1 0; 0 1]);
            overlayMask = true(4);

            mask = dic_postprocess.ops.summaryMaskForStrain(strain, overlayMask);

            testCase.verifyEqual(mask, strain.roiMask);
        end

        function summarizeStrainIgnoresInvalidValues(testCase)
            setupLabKitTestPath();

            strain = struct();
            strain.exx = [1 2; NaN 4];
            strain.eyy = [10 Inf; 20 30];
            mask = true(2);

            T = dic_postprocess.ops.summarizeStrain(strain, mask);

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

            overlay = dic_postprocess.ops.makeStrainOverlay( ...
                reference, strainMap, displayMask, [], opts);

            testCase.verifySize(overlay, [2 2 3]);
            testCase.verifyGreaterThanOrEqual(overlay, 0);
            testCase.verifyLessThanOrEqual(overlay, 1);
        end

        function extendStrainMapHandlesEmptyValidMap(testCase)
            setupLabKitTestPath();

            filled = dic_postprocess.ops.extendStrainMapToRoi([1 2; 3 4], false(2));

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
    opts.colormap = [0 0 1; 1 0 0];
    opts.exportResolution = 96;
    opts.brightness = 0;
    opts.contrast = 1;
    opts.gamma = 1;
    opts.saturation = 1;
    opts.rgbGain = [1 1 1];
end
