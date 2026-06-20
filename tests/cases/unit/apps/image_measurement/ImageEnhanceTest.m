classdef ImageEnhanceTest < matlab.unittest.TestCase
    %IMAGEENHANCETEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'Unit'})
        function test_imageEnhance(testCase)
            setupLabKitTestPath();
            verify_imageEnhance();
        end
    end
end

function verify_imageEnhance()
%TEST_IMAGEENHANCE Verify image enhancement calculations and exports.

    checkBrightnessContrastAndSharpenPipeline();
    checkWhiteBalanceReducesChannelCast();
    checkSelectedFileNormalization();
    checkReadImagesAcceptsPathPanelCellPaths();
    checkManifestAndExportContract();
end

function checkBrightnessContrastAndSharpenPipeline()
    img = syntheticGradientImage();
    steps = [ ...
        image_enhance.ops.makeStep('Brightness/contrast', 10, 25, 0); ...
        image_enhance.ops.makeStep('Sharpen', 40, 1.5, 0)];

    processed = image_enhance.ops.applyPipeline({img}, steps);
    out = processed{1};

    assert(isequal(size(out), size(img)), ...
        'Enhancement pipeline should preserve image size.');
    assert(all(out(:) >= 0 & out(:) <= 1), ...
        'Enhancement pipeline should clamp output to display range.');
    assert(mean(out(:)) > mean(img(:)), ...
        'Positive brightness should increase mean image intensity.');
end

function checkWhiteBalanceReducesChannelCast()
    gray = repmat(linspace(0.2, 0.8, 64), 48, 1);
    castImage = cat(3, 0.55 .* gray, 0.8 .* gray, 1.25 .* gray);
    beforeSpread = channelMeanSpread(castImage);

    step = image_enhance.ops.makeStep('White balance', 100, 0, 0);
    out = image_enhance.ops.applyStep(castImage, step, []);
    afterSpread = channelMeanSpread(out);

    assert(afterSpread < beforeSpread * 0.25, ...
        'Gray-world white balance should reduce channel mean spread.');
end

function checkSelectedFileNormalization()
    folder = tempname;
    mkdir(folder);
    cleanup = onCleanup(@() removeTempFolder(folder));

    paths = image_enhance.io.selectedImagePaths( ...
        {'figure_b.png', 'figure_a.tif'}, folder);
    names = fileNames(paths);
    assert(isequal(names, {'figure_a.tif'; 'figure_b.png'}), ...
        'Selected enhancement images should be sorted by filename.');

    assertThrows(@() image_enhance.io.selectedImagePaths('notes.txt', folder), ...
        'labkit_ImageEnhance_app:UnsupportedImageFile', ...
        'Manual image selection should reject unsupported file types.');
end

function checkReadImagesAcceptsPathPanelCellPaths()
    folder = tempname;
    mkdir(folder);
    cleanup = onCleanup(@() removeTempFolder(folder));

    sourcePath = fullfile(folder, 'figure_a.png');
    imwrite(uint8(80 * ones(8, 9, 3)), sourcePath);

    items = image_enhance.io.readImages({sourcePath});
    assert(numel(items) == 1, ...
        'Image enhance reader should accept pathPanel cell-array paths.');
    assert(items(1).path == string(sourcePath), ...
        'Image enhance reader should preserve the selected source path.');
    assert(isequal(size(items(1).image), [8 9 3]), ...
        'Image enhance reader should load RGB image data from pathPanel paths.');
end

function checkManifestAndExportContract()
    folder = tempname;
    mkdir(folder);
    cleanup = onCleanup(@() removeTempFolder(folder));

    sourcePath = string(fullfile(folder, 'sample.png'));
    imwrite(uint8(120 * ones(10, 12, 3)), sourcePath);
    imwrite(uint8(255 * ones(5, 5, 3)), fullfile(folder, 'sample_enhanced.png'));

    items = image_enhance.io.readImages(sourcePath);
    steps = image_enhance.ops.makeStep('Brightness/contrast', 5, 0, 0);
    payload = image_enhance.export.writeOutputs(items, steps, struct( ...
        'outputFolder', string(folder), ...
        'format', 'PNG'));

    assert(endsWith(payload.results(1).outputPath, "sample_enhanced_001.png"), ...
        'Batch export should avoid overwriting existing enhanced outputs.');
    assert(isfile(payload.results(1).outputPath), ...
        'Batch export should write enhanced image output.');
    assert(isfile(payload.manifestPath), ...
        'Batch export should write a manifest CSV.');

    T = image_enhance.export.buildManifest(payload.results);
    assert(isequal(T.Properties.VariableNames, expectedManifestColumns()), ...
        'Image enhancement manifest columns changed.');
    assert(T.StepCount(1) == 1, 'Manifest should preserve step count.');
end

function img = syntheticGradientImage()
    [x, y] = meshgrid(linspace(0, 1, 72), linspace(0, 1, 48));
    img = cat(3, x, y, 0.5 .* x + 0.5 .* y);
end

function spread = channelMeanSpread(img)
    means = squeeze(mean(img, [1 2]));
    spread = max(means) - min(means);
end

function names = fileNames(paths)
    names = cell(numel(paths), 1);
    for k = 1:numel(paths)
        [~, base, ext] = fileparts(char(paths(k)));
        names{k} = [base ext];
    end
end

function cols = expectedManifestColumns()
    cols = {'SourceImage', 'OutputImage', 'Status', 'Width_px', ...
        'Height_px', 'StepCount', 'Message'};
end

function assertThrows(fcn, expectedId, message)
    try
        fcn();
    catch ME
        assert(strcmp(ME.identifier, expectedId), ...
            'Expected error %s, got %s.', expectedId, ME.identifier);
        return;
    end
    error(message);
end

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
