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
    checkPixelRadiusScalesWithPreview();
    checkReadImagesAcceptsFilePanelCellPaths();
    checkPreviewImageDownsamplesLargeInputs();
    checkManifestAndExportContract();
    checkExportTaskFingerprintTracksInputsOptionsAndSteps();
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

function checkReadImagesAcceptsFilePanelCellPaths()
    folder = tempname;
    mkdir(folder);
    cleanup = onCleanup(@() removeTempFolder(folder));

    sourcePath = fullfile(folder, 'figure_a.png');
    imwrite(uint8(80 * ones(8, 9, 3)), sourcePath);

    items = image_enhance.io.readImages({sourcePath});
    assert(numel(items) == 1, ...
        'Image enhance reader should accept filePanel cell-array paths.');
    assert(items(1).path == string(sourcePath), ...
        'Image enhance reader should preserve the selected source path.');
    assert(isequal(size(items(1).image), [8 9 3]), ...
        'Image enhance reader should load RGB image data from filePanel paths.');
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
    written = im2double(imread(payload.results(1).outputPath));
    assert(isequal(size(written), [10 12 3]), ...
        'Batch export should process and write full-size enhanced images.');
    assert(isfile(payload.manifestPath), ...
        'Batch export should write a manifest CSV.');

    T = image_enhance.export.buildManifest(payload.results);
    assert(isequal(T.Properties.VariableNames, expectedManifestColumns()), ...
        'Image enhancement manifest columns changed.');
    assert(T.StepCount(1) == 1, 'Manifest should preserve step count.');
end

function checkExportTaskFingerprintTracksInputsOptionsAndSteps()
    item = image_enhance.state.emptyItem();
    item.path = "sample.png";
    item.name = "sample.png";
    item.image = syntheticGradientImage();
    step = image_enhance.ops.makeStep('Brightness/contrast', 5, 0, 0);

    base = image_enhance.state.exportTask(item, step, struct( ...
        'outputFolder', "out_a", ...
        'format', 'PNG'));
    repeated = image_enhance.state.exportTask(item, step, struct( ...
        'outputFolder', "out_a", ...
        'format', 'PNG'));
    moved = image_enhance.state.exportTask(item, step, struct( ...
        'outputFolder', "out_b", ...
        'format', 'PNG'));
    changedStep = image_enhance.state.exportTask(item, ...
        image_enhance.ops.makeStep('Brightness/contrast', 6, 0, 0), ...
        struct('outputFolder', "out_a", 'format', 'PNG'));

    assert(base.fingerprint == repeated.fingerprint, ...
        'Identical enhancement export tasks should have stable fingerprints.');
    assert(base.fingerprint ~= moved.fingerprint, ...
        'Changing the enhancement output folder should change the task fingerprint.');
    assert(base.fingerprint ~= changedStep.fingerprint, ...
        'Changing enhancement steps should change the task fingerprint.');
end

function checkPreviewImageDownsamplesLargeInputs()
    img = repmat(linspace(0, 1, 160), 120, 1);
    [preview, scale] = image_enhance.view.previewImage(img, 50);
    assert(size(preview, 3) == 3, ...
        'Enhancement preview should render grayscale inputs as RGB.');
    assert(size(preview, 1) <= 50, ...
        'Enhancement preview should downsample large display images by height.');
    assert(abs(scale - 50 / 120) < 1e-12, ...
        'Enhancement preview should report the display-to-source scale.');
    assert(all(preview(:) >= 0 & preview(:) <= 1), ...
        'Enhancement preview should stay in display range.');
end

function checkPixelRadiusScalesWithPreview()
    img = syntheticGradientImage();
    preview = image_enhance.view.previewImage(img, 24);
    fullStep = image_enhance.ops.makeStep('Local contrast', 50, 12, 0);
    previewStep = image_enhance.ops.makeStep('Local contrast', 50, 6, 0);

    fullProcessed = image_enhance.ops.applyStep(img, fullStep, []);
    fullPreview = image_enhance.view.previewImage(fullProcessed, 24);
    previewProcessed = image_enhance.ops.applyStep(preview, previewStep, []);

    assert(mean(abs(fullPreview(:) - previewProcessed(:))) < 0.04, ...
        'Downsampled previews should scale pixel-radius controls for export-like behavior.');
end

function img = syntheticGradientImage()
    [x, y] = meshgrid(linspace(0, 1, 72), linspace(0, 1, 48));
    img = cat(3, x, y, 0.5 .* x + 0.5 .* y);
end

function spread = channelMeanSpread(img)
    means = squeeze(mean(img, [1 2]));
    spread = max(means) - min(means);
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
