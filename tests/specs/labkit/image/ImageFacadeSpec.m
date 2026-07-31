classdef ImageFacadeSpec < matlab.unittest.TestCase
    %IMAGEFACADEPEC Specify public image file and conversion behavior.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function rejectsUnknownReadOptions(testCase)
            testCase.verifyError(@() labkit.image.readFiles( ...
                strings(0, 1), struct("Normalise", true)), ...
                "labkit:image:InvalidOptions");
        end

        function readsNormalizedImagesAndReportsSemanticProgress(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            gray = fullfile(folder, "gray.png");
            rgba = fullfile(folder, "rgba.png");
            imwrite(uint8(90 * ones(5, 6)), gray);
            imwrite(uint8(130 * ones(4, 7, 3)), rgba, "Alpha", uint8(255 * ones(4, 7)));
            events = {};

            records = labkit.image.readFiles({gray, rgba}, ...
                struct("progressFcn", @capture));

            testCase.verifyEqual(numel(records), 2);
            testCase.verifyEqual(records(1).name, "gray.png");
            testCase.verifyEqual(size(records(1).image), [5, 6, 3]);
            testCase.verifyClass(records(1).image, "double");
            testCase.verifyGreaterThanOrEqual(min(records(1).image, [], "all"), 0);
            testCase.verifyLessThanOrEqual(max(records(1).image, [], "all"), 1);
            testCase.verifyEqual(size(records(2).image), [4, 7, 3]);
            testCase.verifyEqual(string(cellfun(@(event) event.stage, events, ...
                "UniformOutput", false)), ...
                ["beforeRead"; "afterRead"; "beforeRead"; "afterRead"]);

            function capture(event)
                events{end + 1, 1} = event;
            end
        end

        function preservesConversionResizeAndPathContracts(testCase)
            image = zeros(12, 20, 3);
            image(:, :, 1) = 0.35;
            image(:, :, 2) = repmat(linspace(0.1, 0.9, 20), 12, 1);
            image(:, :, 3) = 0.55;

            [preview, scale] = labkit.image.resizeToFit(image, "MaxHeight", 6);
            [budget, info] = labkit.image.previewBudget(image, "MaxPixels", 40, "Expansion", 4);
            [native, nativeInfo] = labkit.image.previewBudget(image);
            rgb = labkit.image.ensureRgb(labkit.image.im2double(uint8(100 * ones(4, 5))));
            paths = labkit.image.normalizePaths([" a.png "; ""; "b.JPG"]);

            testCase.verifyEqual(labkit.image.im2double(uint8([0, 255])), [0, 1]);
            testCase.verifyEqual(size(rgb), [4, 5, 3]);
            testCase.verifyEqual(size(preview), [6, 10, 3]);
            testCase.verifyEqual(scale, 0.5, "AbsTol", 1e-12);
            testCase.verifyLessThan(size(budget, 1), size(image, 1));
            testCase.verifyEqual(info.coordinateScale, 0.2, "AbsTol", 1e-12);
            testCase.verifyEqual(native, image);
            testCase.verifyEqual(nativeInfo.scaleFactor, 1);
            testCase.verifyTrue(isinf(nativeInfo.maxPixels));
            testCase.verifyEqual(paths, ["a.png"; "b.JPG"]);
            testCase.verifyTrue(labkit.image.isSupportedPath("sample.TIFF"));
            testCase.verifyFalse(labkit.image.isSupportedPath("sample.txt"));
            testCase.verifyError(@() labkit.image.normalizePaths("", "AllowEmpty", false), ...
                "labkit:image:NoPaths");
        end
    end
end
