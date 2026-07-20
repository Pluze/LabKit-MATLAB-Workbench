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
    checkWhiteRoiCalibrationAvoidsWashedHighlights();
    checkSubjectPreservingEnhanceLiftsBackgroundWithoutHueDrift();
    checkPixelRadiusScalesWithPreview();
    checkEmptyNumericToolValuesStayScalar();
    checkWhiteRoiToolAvailabilityFollowsBatchMode();
    checkWhiteRoiDefaultUsesImageCorner();
    checkResultTableReportsExportSizeNotPreviewSize();
    checkReadImagesAcceptsFilePanelStringPaths();
    checkReadImagesReportsImportProgress();
    checkPreviewImageDownsamplesLargeInputs();
    checkManifestAndExportContract();
    checkPerImageExportSteps();
    checkExportTaskFingerprintTracksInputsOptionsAndSteps();
    checkExportTaskPreservesPerImageSteps();
    checkAppSdkProjectAndPresenterContracts();
end

function checkAppSdkProjectAndPresenterContracts()
    definition = image_enhance.definition();
    assert(isa(definition, 'labkit.app.Definition'), ...
        'Image Enhance must use the explicit App SDK definition contract.');
    project = definition.ProjectSchema.Create();
    assert(definition.ProjectSchema.Validate(project), ...
        'A new Image Enhance project should satisfy its durable contract.');
    assert(~isfield(project, 'items') && ~isfield(project, 'previewImages'), ...
        'The durable project must not contain decoded pixels or preview caches.');
    session = image_enhance.createSession(project, labkit.app.CallbackContext());
    state = struct('project', project, 'session', session);
    presentation = image_enhance.workbench.present(state);
    assert(isa(presentation, 'labkit.app.view.Snapshot'), ...
        'The presenter should return one explicit semantic snapshot.');
    assert(isempty(session.cache.item) && ...
        ~isfield(session, 'whiteRoiHandle'), ...
        'The rebuildable session must start without pixels or ROI handles.');
end

function checkBrightnessContrastAndSharpenPipeline()
    img = syntheticGradientImage();
    steps = [ ...
        image_enhance.analysisRun.makeStep('Brightness/contrast', 10, 25, 0); ...
        image_enhance.analysisRun.makeStep('Sharpen', 40, 1.5, 0)];

    processed = image_enhance.analysisRun.applyPipeline({img}, steps);
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

    step = image_enhance.analysisRun.makeStep('White balance', 100, 0, 0);
    out = image_enhance.analysisRun.applyStep(castImage, step, []);
    afterSpread = channelMeanSpread(out);

    assert(afterSpread < beforeSpread * 0.25, ...
        'Gray-world white balance should reduce channel mean spread.');
end

function checkWhiteRoiCalibrationAvoidsWashedHighlights()
    img = 0.72 + 0.04 .* syntheticGradientImage();
    img(:, :, 1) = img(:, :, 1) .* 1.06;
    img(:, :, 3) = img(:, :, 3) .* 0.93;
    img(18:36, 24:56, 1) = 0.62;
    img(18:36, 24:56, 2) = 0.34;
    img(18:36, 24:56, 3) = 0.15;
    img = min(max(img, 0), 1);

    step = image_enhance.analysisRun.makeStep('White ROI calibration', 100, 92, 0);
    context = struct('whiteRoi', [2 2 18 14]);
    out = image_enhance.analysisRun.applyStep(img, step, context);
    bg = out(2:15, 2:19, :);
    subjectBefore = img(18:36, 24:56, :);
    subjectAfter = out(18:36, 24:56, :);

    bgLuma = mean(testLuma(bg), 'all');
    assert(bgLuma > 0.86 && bgLuma < 0.985, ...
        'White ROI calibration should move the sampled background near white without clipping.');
    bgBeforeMean = squeeze(mean(img(2:15, 2:19, :), [1 2])).';
    bgAfterMean = squeeze(mean(bg, [1 2])).';
    subjectBeforeMean = squeeze(mean(subjectBefore, [1 2])).';
    subjectAfterMean = squeeze(mean(subjectAfter, [1 2])).';
    assert(norm(subjectAfterMean - bgAfterMean) > ...
        norm(subjectBeforeMean - bgBeforeMean), ...
        'White ROI calibration should increase subject-background separation.');
    assert(mean(subjectAfter(:, :, 1), 'all') > mean(subjectAfter(:, :, 3), 'all'), ...
        'White ROI calibration should preserve warm subject color after correction.');
    beforeHsv = rgb2hsv(subjectBefore);
    afterHsv = rgb2hsv(subjectAfter);
    hueShift = circularHueDistance(mean(beforeHsv(:, :, 1), 'all'), ...
        mean(afterHsv(:, :, 1), 'all'));
    saturationRatio = mean(afterHsv(:, :, 2), 'all') ./ ...
        max(mean(beforeHsv(:, :, 2), 'all'), eps);
    assert(hueShift < 0.035, ...
        'White ROI calibration should not over-shift subject hue.');
    assert(saturationRatio > 0.85 && saturationRatio < 1.25, ...
        'White ROI calibration should keep subject saturation changes modest.');
end

function checkSubjectPreservingEnhanceLiftsBackgroundWithoutHueDrift()
    img = 0.55 .* ones(48, 72, 3);
    img(:, :, 1) = img(:, :, 1) .* 0.96;
    img(:, :, 2) = img(:, :, 2) .* 1.04;
    img(:, :, 3) = img(:, :, 3) .* 1.02;
    img(18:35, 24:52, 1) = 0.72;
    img(18:35, 24:52, 2) = 0.42;
    img(18:35, 24:52, 3) = 0.14;
    img = min(max(img, 0), 1);

    step = image_enhance.analysisRun.makeStep('Subject-preserving enhance', 85, 90, 0);
    weakStep = image_enhance.analysisRun.makeStep('Subject-preserving enhance', 20, 70, 0);
    out = image_enhance.analysisRun.applyStep(img, step, []);
    weakOut = image_enhance.analysisRun.applyStep(img, weakStep, []);
    backgroundBefore = testLuma(img(1:12, 1:20, :));
    backgroundAfter = testLuma(out(1:12, 1:20, :));
    weakBackgroundAfter = testLuma(weakOut(1:12, 1:20, :));
    subjectBefore = img(18:35, 24:52, :);
    subjectAfter = out(18:35, 24:52, :);
    beforeHsv = rgb2hsv(subjectBefore);
    afterHsv = rgb2hsv(subjectAfter);
    hueShift = circularHueDistance(mean(beforeHsv(:, :, 1), 'all'), ...
        mean(afterHsv(:, :, 1), 'all'));
    saturationRatio = mean(afterHsv(:, :, 2), 'all') ./ ...
        max(mean(beforeHsv(:, :, 2), 'all'), eps);

    assert(mean(backgroundAfter, 'all') > mean(backgroundBefore, 'all'), ...
        'Subject-preserving enhance should not darken a dull low-saturation background.');
    assert(mean(backgroundAfter, 'all') > mean(weakBackgroundAfter, 'all') + 0.03, ...
        'Subject-preserving enhance should respond monotonically to stronger background lifting settings.');
    assert(hueShift < 0.035, ...
        'Subject-preserving enhance should not strongly shift subject hue.');
    assert(saturationRatio > 0.80 && saturationRatio < 1.20, ...
        'Subject-preserving enhance should keep subject saturation changes modest.');
end

function checkEmptyNumericToolValuesStayScalar()
    step = image_enhance.analysisRun.makeStep('Brightness/contrast', [], [], []);
    assert(isscalar(step) && isequal(size(step), [1 1]), ...
        'Enhancement tool steps should remain scalar when UI controls report empty numeric values.');
    assert(step.amount == 0 && step.secondary == 0 && step.referenceIndex == 0, ...
        'Empty numeric tool values should fall back to scalar defaults.');

    item = image_enhance.sourceFiles.emptyItem();
    item.path = "sample.png";
    item.name = "sample.png";
    item.image = syntheticGradientImage();
    task = image_enhance.resultFiles.exportTask( ...
        item, step, struct('outputFolder', "out"));
    assert(contains(task.fingerprint, "stepCount=1"), ...
        'Scalar fallback steps should remain valid export-task inputs.');
end

function checkWhiteRoiToolAvailabilityFollowsBatchMode()
    spec = image_enhance.projectSpec();
    project = spec.Create();
    session = image_enhance.createSession(project, labkit.app.CallbackContext());
    project.inputs.sources = struct('id', "image-1", 'required', true, ...
        'role', "source-image", 'reference', struct());
    annotation = image_enhance.enhancementAnnotations.empty();
    annotation.sourceId = "image-1";
    project.annotations.items = annotation;
    session.selection.currentIndex = 1;
    session.cache.item = image_enhance.sourceFiles.emptyItem();
    S = struct('project', project, 'session', session);

    availability = image_enhance.imagePreview.presentationData.toolAvailability(S, 'White ROI calibration');
    assert(~availability.canSetWhiteRoi && ~availability.canApply, ...
        'White ROI controls should stay disabled in shared batch mode.');

    S.project.parameters.batchMode = false;
    availability = image_enhance.imagePreview.presentationData.toolAvailability(S, 'White ROI calibration');
    assert(availability.canSetWhiteRoi && ~availability.canApply, ...
        'Turning off shared batch mode should immediately enable ROI selection.');

    S.project.annotations.items.whiteRoi = [1 1 4 4];
    availability = image_enhance.imagePreview.presentationData.toolAvailability(S, 'White ROI calibration');
    assert(availability.canSetWhiteRoi && availability.canApply, ...
        'A per-image white ROI should enable applying the tool for the selected image.');
    assert(~availability.canPreviewPending, ...
        'White ROI movement should not trigger expensive pending preview recomputation.');
end

function checkWhiteRoiDefaultUsesImageCorner()
    position = image_enhance.imagePreview.presentationData.defaultWhiteRoi([100 200 3]);
    assert(position(1) <= 10 && position(2) <= 10, ...
        'Default white ROI should start near the image corner instead of the center.');
    assert(position(3) == 40 && position(4) == 20, ...
        'Default white ROI should keep the existing 20 percent image-size footprint.');

    smallPosition = image_enhance.imagePreview.presentationData.defaultWhiteRoi([6 5 3]);
    assert(isequal(smallPosition, [1 1 5 6]), ...
        'Default white ROI should clamp to small image bounds.');
end

function checkResultTableReportsExportSizeNotPreviewSize()
    item = image_enhance.sourceFiles.emptyItem();
    item.name = "large.png";
    item.image = zeros(2400, 3200, 3);
    previewImage = zeros(1500, 2000, 3);

    data = image_enhance.imagePreview.presentationData.resultTableData(item, previewImage, 0);
    metricNames = string(data(:, 1));
    outputValue = string(data(metricNames == "Output size", 2));

    assert(outputValue == "3200 x 2400 px", ...
        'Image Enhance should report export/source size, not display-preview size.');
end

function checkReadImagesAcceptsFilePanelStringPaths()
    folder = tempname;
    mkdir(folder);
    cleanup = onCleanup(@() removeTempFolder(folder));

    sourcePath = fullfile(folder, 'figure_a.png');
    imwrite(uint8(80 * ones(8, 9, 3)), sourcePath);

    items = image_enhance.sourceFiles.readImages(reshape(string(sourcePath), [], 1));
    assert(numel(items) == 1, ...
        'Image enhance reader should accept filePanel string-column paths.');
    assert(items(1).path == string(sourcePath), ...
        'Image enhance reader should preserve the selected source path.');
    assert(isequal(size(items(1).image), [8 9 3]), ...
        'Image enhance reader should load RGB image data from filePanel paths.');
end

function checkReadImagesReportsImportProgress()
    folder = tempname;
    mkdir(folder);
    cleanup = onCleanup(@() removeTempFolder(folder));

    firstPath = fullfile(folder, 'figure_a.png');
    secondPath = fullfile(folder, 'figure_b.png');
    imwrite(uint8(80 * ones(8, 9, 3)), firstPath);
    imwrite(uint8(120 * ones(7, 6, 3)), secondPath);
    events = {};

    items = image_enhance.sourceFiles.readImages([string(firstPath); string(secondPath)], ...
        struct('progressFcn', @captureProgress));

    stages = string(cellfun(@(event) event.stage, events, 'UniformOutput', false));
    names = string(cellfun(@(event) event.name, events, 'UniformOutput', false));
    assert(numel(items) == 2 && isequal(stages(:), ...
        ["beforeRead"; "afterRead"; "beforeRead"; "afterRead"]), ...
        'Image enhance reader should report before/after progress for every imported file.');
    assert(isequal(names(:), ["figure_a.png"; "figure_a.png"; "figure_b.png"; "figure_b.png"]), ...
        'Image enhance progress events should identify the file being read.');

    function captureProgress(event)
        events{end + 1, 1} = event;
    end
end

function checkManifestAndExportContract()
    folder = tempname;
    mkdir(folder);
    cleanup = onCleanup(@() removeTempFolder(folder));

    sourcePath = string(fullfile(folder, 'sample.png'));
    imwrite(uint8(120 * ones(10, 12, 3)), sourcePath);
    imwrite(uint8(255 * ones(5, 5, 3)), fullfile(folder, 'sample_enhanced.png'));

    items = image_enhance.sourceFiles.readImages(sourcePath);
    steps = image_enhance.analysisRun.makeStep('Brightness/contrast', 5, 0, 0);
    payload = image_enhance.resultFiles.writeOutputs(items, steps, struct( ...
        'outputFolder', string(folder), ...
        'format', 'PNG'));

    assert(endsWith(payload.results(1).outputPath, "sample_enhanced_001.png"), ...
        'Batch export should avoid overwriting existing enhanced outputs.');
    assert(isfile(payload.results(1).outputPath), ...
        'Batch export should write enhanced image output.');
    written = labkit.image.im2double(imread(payload.results(1).outputPath));
    assert(isequal(size(written), [10 12 3]), ...
        'Batch export should process and write full-size enhanced images.');
    assert(isfile(payload.manifestPath), ...
        'Batch export should write a manifest CSV.');

    T = image_enhance.resultFiles.buildManifest(payload.results);
    assert(isequal(T.Properties.VariableNames, expectedManifestColumns()), ...
        'Image enhancement manifest columns changed.');
    assert(T.StepCount(1) == 1, 'Manifest should preserve step count.');
end

function checkPerImageExportSteps()
    folder = tempname;
    mkdir(folder);
    cleanup = onCleanup(@() removeTempFolder(folder));

    firstPath = string(fullfile(folder, 'first.png'));
    secondPath = string(fullfile(folder, 'second.png'));
    imwrite(uint8(80 * ones(8, 9, 3)), firstPath);
    imwrite(uint8(120 * ones(8, 9, 3)), secondPath);
    items = image_enhance.sourceFiles.readImages([firstPath; secondPath]);
    itemSteps = {
        image_enhance.analysisRun.makeStep('Brightness/contrast', 20, 0, 0)
        image_enhance.analysisRun.makeStep('Brightness/contrast', -20, 0, 0)
        };

    payload = image_enhance.resultFiles.writeOutputs(items, ...
        repmat(image_enhance.analysisRun.emptyStep(), 0, 1), struct( ...
        'outputFolder', string(folder), ...
        'format', 'PNG', ...
        'itemSteps', {itemSteps}));

    T = image_enhance.resultFiles.buildManifest(payload.results);
    assert(all(T.StepCount == [1; 1]), ...
        'Per-image enhancement exports should report each image history length.');
    firstWritten = labkit.image.im2double(imread(payload.results(1).outputPath));
    secondWritten = labkit.image.im2double(imread(payload.results(2).outputPath));
    assert(mean(firstWritten(:)) > mean(items(1).image(:)) && ...
        mean(secondWritten(:)) < mean(items(2).image(:)), ...
        'Per-image enhancement exports should apply each image-specific history.');
end

function checkExportTaskFingerprintTracksInputsOptionsAndSteps()
    item = image_enhance.sourceFiles.emptyItem();
    item.path = "sample.png";
    item.name = "sample.png";
    item.image = syntheticGradientImage();
    step = image_enhance.analysisRun.makeStep('Brightness/contrast', 5, 0, 0);

    base = image_enhance.resultFiles.exportTask(item, step, struct( ...
        'outputFolder', "out_a", ...
        'format', 'PNG'));
    repeated = image_enhance.resultFiles.exportTask(item, step, struct( ...
        'outputFolder', "out_a", ...
        'format', 'PNG'));
    moved = image_enhance.resultFiles.exportTask(item, step, struct( ...
        'outputFolder', "out_b", ...
        'format', 'PNG'));
    changedStep = image_enhance.resultFiles.exportTask(item, ...
        image_enhance.analysisRun.makeStep('Brightness/contrast', 6, 0, 0), ...
        struct('outputFolder', "out_a", 'format', 'PNG'));

    assert(base.fingerprint == repeated.fingerprint, ...
        'Identical enhancement export tasks should have stable fingerprints.');
    assert(base.fingerprint ~= moved.fingerprint, ...
        'Changing the enhancement output folder should change the task fingerprint.');
    assert(base.fingerprint ~= changedStep.fingerprint, ...
        'Changing enhancement steps should change the task fingerprint.');
end

function checkExportTaskPreservesPerImageSteps()
    items = repmat(image_enhance.sourceFiles.emptyItem(), 2, 1);
    for k = 1:2
        items(k).path = "sample_" + string(k) + ".png";
        items(k).name = "sample_" + string(k) + ".png";
        items(k).image = syntheticGradientImage();
    end
    firstStep = image_enhance.analysisRun.makeStep('Brightness/contrast', 6, 0, 0);
    secondStep = image_enhance.analysisRun.makeStep('Brightness/contrast', -6, 0, 0);
    itemSteps = {firstStep; secondStep};
    task = image_enhance.resultFiles.exportTask(items, ...
        repmat(image_enhance.analysisRun.emptyStep(), 0, 1), struct( ...
        'outputFolder', "out", 'format', 'PNG', 'itemSteps', {itemSteps}));
    assert(numel(task.itemSteps) == 2, ...
        'Per-image export tasks should preserve individual histories.');
    assert(contains(task.fingerprint, "itemStepCount[2]=1"), ...
        'Per-image export tasks should include item-step fingerprints.');
end

function gray = testLuma(imageIn)
    gray = labkit.image.rgb2gray(imageIn);
end

function checkPreviewImageDownsamplesLargeInputs()
    img = repmat(linspace(0, 1, 160), 120, 1);
    [preview, scale] = image_enhance.imagePreview.presentationData.previewImage(img, 50);
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
    preview = image_enhance.imagePreview.presentationData.previewImage(img, 24);
    fullStep = image_enhance.analysisRun.makeStep('Local contrast', 50, 12, 0);
    previewStep = image_enhance.analysisRun.makeStep('Local contrast', 50, 6, 0);

    fullProcessed = image_enhance.analysisRun.applyStep(img, fullStep, []);
    fullPreview = image_enhance.imagePreview.presentationData.previewImage(fullProcessed, 24);
    previewProcessed = image_enhance.analysisRun.applyStep(preview, previewStep, []);

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

function value = circularHueDistance(a, b)
    delta = abs(a - b);
    value = min(delta, 1 - delta);
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
