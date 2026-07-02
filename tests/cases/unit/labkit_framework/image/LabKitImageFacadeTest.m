classdef LabKitImageFacadeTest < matlab.unittest.TestCase
    %LABKITIMAGEFACADETEST Verify reusable image file input contracts.

    methods (Test, TestTags = {'Unit'})
        function imageFacadeNormalizesReadsAndReportsProgress(testCase)
            setupLabKitTestPath();
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() removeTempFolder(folder));

            grayPath = fullfile(folder, "gray.png");
            rgbaPath = fullfile(folder, "rgba.png");
            imwrite(uint8(90 * ones(5, 6)), grayPath);
            imwrite(uint8(130 * ones(4, 7, 3)), rgbaPath, "Alpha", uint8(255 * ones(4, 7)));
            events = {};

            records = labkit.image.readFiles({char(grayPath), char(rgbaPath)}, ...
                struct("progressFcn", @captureProgress));

            testCase.verifyEqual(numel(records), 2);
            testCase.verifyEqual(records(1).path, string(grayPath));
            testCase.verifyEqual(records(1).name, "gray.png");
            testCase.verifyEqual(size(records(1).image), [5 6 3]);
            testCase.verifyClass(records(1).image, "double");
            testCase.verifyGreaterThanOrEqual(min(records(1).image, [], "all"), 0);
            testCase.verifyLessThanOrEqual(max(records(1).image, [], "all"), 1);
            testCase.verifyEqual(size(records(2).image), [4 7 3]);

            stages = string(cellfun(@(event) event.stage, events, ...
                "UniformOutput", false));
            names = string(cellfun(@(event) event.name, events, ...
                "UniformOutput", false));
            testCase.verifyEqual(stages(:), ...
                ["beforeRead"; "afterRead"; "beforeRead"; "afterRead"]);
            testCase.verifyEqual(names(:), ...
                ["gray.png"; "gray.png"; "rgba.png"; "rgba.png"]);

            function captureProgress(event)
                events{end + 1, 1} = event;
            end
        end

        function imageFacadeKeepsRawDataWhenRequested(testCase)
            setupLabKitTestPath();
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() removeTempFolder(folder));

            sourcePath = fullfile(folder, "raw.tif");
            source = uint16(42 * ones(3, 4));
            imwrite(source, sourcePath);

            records = labkit.image.readFiles(sourcePath, struct("Normalize", false));

            testCase.verifyEqual(records.image, source);
        end

        function imageFacadeProcessesAndResizesImages(testCase)
            setupLabKitTestPath();
            image = zeros(12, 20, 3);
            image(:, :, 1) = 0.35;
            image(:, :, 2) = repmat(linspace(0.1, 0.9, 20), 12, 1);
            image(:, :, 3) = 0.55;

            rgb = labkit.image.toRgbDouble(uint8(100 * ones(4, 5)));
            [preview, scale] = labkit.image.resizeToFit(image, "MaxHeight", 6);
            [budgetPreview, budgetInfo] = labkit.image.previewBudget(image, ...
                "MaxPixels", 40, ...
                "Expansion", 4);
            meanPlane = labkit.image.meanFilter2([0 0 0; 0 1 0; 0 0 0], 3);
            bright = labkit.image.adjustBrightnessContrast(image, 10, 20);
            saturated = labkit.image.adjustHueSaturation(image, 0, 25);
            balanced = labkit.image.grayWorldWhiteBalance(image, 100, 0);
            local = labkit.image.localContrast(image, 50, 2);
            sharp = labkit.image.sharpen(image, 50, 1);

            testCase.verifyEqual(size(rgb), [4 5 3]);
            testCase.verifyEqual(size(preview), [6 10 3]);
            testCase.verifyEqual(scale, 0.5, "AbsTol", 1e-12);
            testCase.verifyLessThan(size(budgetPreview, 1), size(image, 1));
            testCase.verifyEqual(budgetInfo.scaleFactor, 5);
            testCase.verifyEqual(budgetInfo.coordinateScale, 0.2, "AbsTol", 1e-12);
            testCase.verifyEqual(meanPlane(2, 2), 1 / 9, "AbsTol", 1e-12);
            testCase.verifyEqual(meanPlane(1, 1), 1 / 4, "AbsTol", 1e-12);
            testCase.verifyGreaterThan(mean(bright(:)), mean(image(:)));
            testCase.verifyEqual(size(saturated), size(image));
            testCase.verifyLessThan(channelMeanSpread(balanced), channelMeanSpread(image));
            testCase.verifyEqual(size(local), size(image));
            testCase.verifyEqual(size(sharp), size(image));
            testCase.verifyGreaterThanOrEqual(min(sharp, [], "all"), 0);
            testCase.verifyLessThanOrEqual(max(sharp, [], "all"), 1);
        end

        function imageFacadeWritesImageFiles(testCase)
            setupLabKitTestPath();
            folder = tempname;
            cleanup = onCleanup(@() removeTempFolder(folder));
            filepath = fullfile(folder, "nested", "out.png");

            labkit.image.writeFile(0.5 .* ones(4, 5, 3), filepath);

            testCase.verifyTrue(isfile(filepath));
            written = im2double(imread(filepath));
            testCase.verifyEqual(size(written), [4 5 3]);
        end

        function imageFacadeExposesFiltersAndPathPolicy(testCase)
            setupLabKitTestPath();

            filter = labkit.image.fileDialogFilter();
            filterWithAll = labkit.image.fileDialogFilter("IncludeAll", true);
            extensions = labkit.image.supportedExtensions();
            paths = labkit.image.normalizePaths([" a.png "; ""; "b.JPG"]);

            testCase.verifyEqual(filter, {'*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp', ...
                'Image files (*.png, *.jpg, *.jpeg, *.tif, *.tiff, *.bmp)'});
            testCase.verifyEqual(size(filterWithAll, 1), 2);
            testCase.verifyTrue(any(extensions == ".png"));
            testCase.verifyEqual(paths, ["a.png"; "b.JPG"]);
            testCase.verifyTrue(labkit.image.isSupportedPath("sample.TIFF"));
            testCase.verifyFalse(labkit.image.isSupportedPath("sample.txt"));
            testCase.verifyEqual(labkit.image.displayName("/tmp/folder/sample.tif"), ...
                "sample.tif");
            testCase.verifyError(@() labkit.image.assertSupportedPaths("sample.txt"), ...
                "labkit:image:UnsupportedImageFile");
            testCase.verifyError(@() labkit.image.normalizePaths("", "AllowEmpty", false), ...
                "labkit:image:NoPaths");
        end
    end
end

function spread = channelMeanSpread(imageData)
    channelMeans = squeeze(mean(imageData, [1 2])).';
    spread = max(channelMeans) - min(channelMeans);
end

function removeTempFolder(folder)
    if exist(folder, "dir") == 7
        rmdir(folder, "s");
    end
end
