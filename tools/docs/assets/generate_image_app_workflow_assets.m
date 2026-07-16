% Generate reproducible image app workflow assets for maintainer guides.
%
% Command-line use:
%   matlab -batch "run('tools/docs/assets/generate_image_app_workflow_assets.m')"
%
% Optional output override:
%   setenv("LABKIT_DOC_ASSET_OUTPUT", "/tmp/labkit-image-workflow-assets")
%   run("tools/docs/assets/generate_image_app_workflow_assets.m")
%
% The script uses synthetic, non-sensitive images and routes them through the
% app-owned Image Enhance, Image Match, and Batch Image Crop packages. It also
% opens the real app windows to capture parameter-panel screenshots.

repoRoot = fileparts(fileparts(fileparts(fileparts(mfilename("fullpath")))));
outputRoot = resolveOutputRoot(repoRoot);
assetDir = fullfile(outputRoot, "assets");
inputDir = fullfile(outputRoot, "workflow_inputs");
exportDir = fullfile(outputRoot, "workflow_exports");

resetDir(assetDir);
resetDir(inputDir);
resetDir(exportDir);

addpath(repoRoot);
addpath(fullfile(repoRoot, "apps"), "-end");
addpath(fullfile(repoRoot, "apps", "image_measurement", "image_enhance"), "-end");
addpath(fullfile(repoRoot, "apps", "image_measurement", "image_match"), "-end");
addpath(fullfile(repoRoot, "apps", "image_measurement", "batch_crop"), "-end");

inputs = writeSyntheticWorkflowInputs(inputDir);
runImageEnhanceWorkflow(inputs, assetDir, exportDir);
runImageMatchWorkflow(inputs, assetDir, exportDir);
runBatchCropWorkflow(inputs, assetDir, exportDir);

captureLauncher(assetDir);
captureImageEnhanceParameters(assetDir);
captureImageMatchParameters(assetDir);
captureBatchCropParameters(assetDir);

fprintf("LabKit image workflow assets written to:\n  %s\n", outputRoot);

function outputRoot = resolveOutputRoot(repoRoot)
    value = string(getenv("LABKIT_DOC_ASSET_OUTPUT"));
    if strlength(value) == 0
        outputRoot = fullfile(repoRoot, "artifacts", "doc-assets", ...
            "image-app-workflows");
        return;
    end

    if isfolder(fileparts(char(value))) || startsWith(value, filesep)
        outputRoot = char(value);
    else
        outputRoot = fullfile(repoRoot, char(value));
    end
end

function inputs = writeSyntheticWorkflowInputs(inputDir)
    [x, y] = meshgrid(linspace(0, 1, 900), linspace(0, 1, 640));
    ring = exp(-((x - 0.56) .^ 2 + (y - 0.50) .^ 2) ./ 0.018);
    texture = 0.05 .* sin(36 .* x) .* cos(28 .* y);

    low = min(max(0.20 + 0.45 .* x + 0.22 .* ring + texture, 0), 1);
    lowRgb = cat(3, low .* 0.92, low .* 0.88, low .* 0.78);

    ref = min(max(0.40 + 0.42 .* y + 0.20 .* ring + ...
        0.03 .* sin(22 .* y), 0), 1);
    refRgb = cat(3, ref .* 1.05, ref .* 0.95, ref .* 0.82);

    source = min(max(0.26 + 0.48 .* x + 0.20 .* ring + ...
        0.04 .* cos(18 .* x), 0), 1);
    sourceRgb = cat(3, source .* 0.70, source .* 0.88, source .* 1.10);

    cropRgb = microscopeLikeImage(960, 720);

    inputs.enhance = fullfile(inputDir, "goal2_dim_source.png");
    inputs.matchReference = fullfile(inputDir, "goal3_reference_style.png");
    inputs.matchSource = fullfile(inputDir, "goal3_cool_source.png");
    inputs.cropSource = fullfile(inputDir, "goal4_microscope_source.png");

    imwrite(lowRgb, inputs.enhance);
    imwrite(refRgb, inputs.matchReference);
    imwrite(sourceRgb, inputs.matchSource);
    imwrite(cropRgb, inputs.cropSource);
end

function imageData = microscopeLikeImage(widthPx, heightPx)
    [cx, cy] = meshgrid(1:widthPx, 1:heightPx);
    imageData = zeros(heightPx, widthPx, 3);
    imageData(:, :, 1) = 0.18 + 0.30 .* normalize01(cx);
    imageData(:, :, 2) = 0.22 + 0.26 .* normalize01(cy);
    imageData(:, :, 3) = 0.28 + 0.18 .* normalize01(cx + cy);

    for k = 1:6
        centerX = 160 + k * 115;
        centerY = 180 + mod(k, 3) * 130;
        blob = exp(-((cx - centerX) .^ 2 + (cy - centerY) .^ 2) ./ ...
            (2 * 34 ^ 2));
        imageData(:, :, 1) = imageData(:, :, 1) + 0.18 .* blob;
        imageData(:, :, 2) = imageData(:, :, 2) + 0.25 .* blob;
        imageData(:, :, 3) = imageData(:, :, 3) + 0.10 .* blob;
    end
    imageData = min(max(imageData, 0), 1);
end

function runImageEnhanceWorkflow(inputs, assetDir, exportRoot)
    outputFolder = fullfile(exportRoot, "image_enhance");
    ensureDir(outputFolder);
    items = image_enhance.sourceFiles.readImages(string(inputs.enhance));
    steps = [ ...
        image_enhance.analysisRun.makeStep("Brightness/contrast", 18, 26, 0); ...
        image_enhance.analysisRun.makeStep("Local contrast", 34, 10, 0); ...
        image_enhance.analysisRun.makeStep("Sharpen", 22, 1.5, 0)];
    opts = struct("outputFolder", string(outputFolder), "format", "PNG");
    payload = image_enhance.resultFiles.writeOutputs(items, steps, opts);
    processed = labkit.image.im2double(imread(char(payload.results(1).outputPath)));

    exportPairImage(items(1).image, processed, ...
        fullfile(assetDir, "workflow_image_enhance_before_after.png"), ...
        "Source", "Enhanced export");
    copyfile(char(payload.results(1).outputPath), ...
        fullfile(assetDir, "workflow_image_enhance_export.png"));
end

function runImageMatchWorkflow(inputs, assetDir, exportRoot)
    outputFolder = fullfile(exportRoot, "image_match");
    ensureDir(outputFolder);
    reference = image_match.sourceFiles.readImages(string(inputs.matchReference));
    items = image_match.sourceFiles.readImages(string(inputs.matchSource));
    steps = image_match.analysisRun.makeStep("Balanced", 85, 70, 80);
    opts = struct("outputFolder", string(outputFolder), "format", "PNG");
    payload = image_match.resultFiles.writeOutputs(items, reference, steps, opts);
    matched = labkit.image.im2double(imread(char(payload.results(1).outputPath)));

    exportTriptychImage(reference(1).image, items(1).image, matched, ...
        fullfile(assetDir, ...
        "workflow_image_match_reference_source_output.png"), ...
        "Reference", "Source", "Matched export");
    copyfile(char(payload.results(1).outputPath), ...
        fullfile(assetDir, "workflow_image_match_export.png"));
end

function runBatchCropWorkflow(inputs, assetDir, exportRoot)
    outputFolder = fullfile(exportRoot, "batch_crop");
    ensureDir(outputFolder);
    items = batch_crop.appState.readItems(string(inputs.cropSource));
    items(1).angleDeg = 3;
    items(1).centerXY = [515, 350];
    items(1).centerSet = true;
    opts = struct( ...
        "outputFolder", string(outputFolder), ...
        "format", "PNG", ...
        "scaleMode", "Pixels", ...
        "cropWidth", 420, ...
        "cropHeight", 320, ...
        "paddingPercent", 18);
    payload = batch_crop.resultFiles.writeOutputs(items, opts);
    cropped = labkit.image.im2double(imread(char(payload.results(1).outputPath)));
    source = labkit.image.im2double(imread(inputs.cropSource));
    marked = drawCropBox(source, items(1).centerXY, ...
        opts.cropWidth, opts.cropHeight);

    exportPairImage(marked, cropped, ...
        fullfile(assetDir, "workflow_batch_crop_source_output.png"), ...
        "Source with target", "Cropped export");
    copyfile(char(payload.results(1).outputPath), ...
        fullfile(assetDir, "workflow_batch_crop_export.png"));
end

function captureLauncher(assetDir)
    fig = [];
    try
        fig = labkit_launcher();
        prepareFigure(fig);
        exportapp(fig, fullfile(assetDir, "screenshot_launcher.png"));
    catch ME
        warning("LabKit:GuideAssets:ScreenshotFailed", ...
            "Could not capture launcher screenshot: %s", ME.message);
    end
    closeIfValid(fig);
end

function captureImageEnhanceParameters(assetDir)
    fig = [];
    try
        fig = labkit_ImageEnhance_app();
        prepareFigure(fig);
        ui = getappdata(fig, "labkitUiRegistry");
        selectControlTab(ui, "toolsHistoryTab");
        setVisualControlValue(ui, "toolKind", "Brightness/contrast");
        setVisualControlValue(ui, "toolAmount", 18);
        setVisualControlValue(ui, "toolSecondary", 26);
        drawnow;
        pause(0.6);
        exportapp(fig, fullfile(assetDir, ...
            "screenshot_image_enhance_parameters.png"));
    catch ME
        warning("LabKit:GuideAssets:ScreenshotFailed", ...
            "Could not capture Image Enhance parameters: %s", ME.message);
    end
    closeIfValid(fig);
end

function captureImageMatchParameters(assetDir)
    fig = [];
    try
        fig = labkit_ImageMatch_app();
        prepareFigure(fig);
        ui = getappdata(fig, "labkitUiRegistry");
        selectControlTab(ui, "matchHistoryTab");
        setVisualControlValue(ui, "matchMethod", "Balanced");
        setVisualControlValue(ui, "matchStrength", 85);
        setVisualControlValue(ui, "toneStrength", 70);
        setVisualControlValue(ui, "colorStrength", 80);
        drawnow;
        pause(0.6);
        exportapp(fig, fullfile(assetDir, ...
            "screenshot_image_match_parameters.png"));
    catch ME
        warning("LabKit:GuideAssets:ScreenshotFailed", ...
            "Could not capture Image Match parameters: %s", ME.message);
    end
    closeIfValid(fig);
end

function captureBatchCropParameters(assetDir)
    fig = [];
    try
        fig = labkit_BatchImageCrop_app();
        prepareFigure(fig);
        ui = getappdata(fig, "labkitUiRegistry");
        selectControlTab(ui, "filesAnalysisTab");
        setVisualControlValue(ui, "cropWidth", 420);
        setVisualControlValue(ui, "cropHeight", 320);
        setVisualControlValue(ui, "rotation", 3);
        setVisualControlValue(ui, "paddingPercent", 18);
        setVisualControlValue(ui, "centerX", 515);
        setVisualControlValue(ui, "centerY", 350);
        drawnow;
        pause(0.6);
        exportapp(fig, fullfile(assetDir, ...
            "screenshot_batch_crop_parameters.png"));
    catch ME
        warning("LabKit:GuideAssets:ScreenshotFailed", ...
            "Could not capture Batch Crop parameters: %s", ME.message);
    end
    closeIfValid(fig);
end

function selectControlTab(ui, tabField)
    if ~isstruct(ui) || ~isfield(ui, tabField)
        return;
    end
    tabHandle = ui.(tabField);
    tabHandle.Parent.SelectedTab = tabHandle;
    drawnow;
    pause(0.2);
end

function setVisualControlValue(ui, id, value)
% Set one generated-screenshot control without exposing a production facade.
    control = ui.controls.(char(string(id)));
    if isfield(control, 'setValue') && isa(control.setValue, 'function_handle')
        control.setValue(value);
        return;
    end
    candidates = {'valueHandle', 'handle', 'dropdown', 'listbox', ...
        'table', 'textArea', 'displayField'};
    for k = 1:numel(candidates)
        if isfield(control, candidates{k}) && ~isempty(control.(candidates{k}))
            control.(candidates{k}).Value = value;
            return;
        end
    end
    error('LabKit:GuideAssets:MissingControlValue', ...
        'Screenshot control %s does not expose a value handle.', id);
end

function exportPairImage(leftImage, rightImage, outputPath, leftTitle, rightTitle)
    fig = figure("Visible", "off", "Color", "w", ...
        "Position", [100 100 1200 520]);
    tiledlayout(fig, 1, 2, "Padding", "compact", ...
        "TileSpacing", "compact");
    ax = nexttile;
    displayImage(ax, leftImage);
    title(leftTitle, "FontWeight", "bold");
    ax = nexttile;
    displayImage(ax, rightImage);
    title(rightTitle, "FontWeight", "bold");
    exportgraphics(fig, outputPath, "Resolution", 180);
    close(fig);
end

function exportTriptychImage(firstImage, secondImage, thirdImage, outputPath, ...
        firstTitle, secondTitle, thirdTitle)
    fig = figure("Visible", "off", "Color", "w", ...
        "Position", [100 100 1440 520]);
    tiledlayout(fig, 1, 3, "Padding", "compact", ...
        "TileSpacing", "compact");
    ax = nexttile;
    displayImage(ax, firstImage);
    title(firstTitle, "FontWeight", "bold");
    ax = nexttile;
    displayImage(ax, secondImage);
    title(secondTitle, "FontWeight", "bold");
    ax = nexttile;
    displayImage(ax, thirdImage);
    title(thirdTitle, "FontWeight", "bold");
    exportgraphics(fig, outputPath, "Resolution", 180);
    close(fig);
end

function displayImage(ax, imageData)
    image(ax, imageData);
    axis(ax, "image");
    axis(ax, "off");
end

function marked = drawCropBox(imageData, centerXY, widthPx, heightPx)
    marked = labkit.image.im2double(imageData);
    x1 = max(1, round(centerXY(1) - widthPx / 2));
    x2 = min(size(marked, 2), round(centerXY(1) + widthPx / 2));
    y1 = max(1, round(centerXY(2) - heightPx / 2));
    y2 = min(size(marked, 1), round(centerXY(2) + heightPx / 2));
    marked = paintLine(marked, x1:x2, y1, [1 0.15 0.05]);
    marked = paintLine(marked, x1:x2, y2, [1 0.15 0.05]);
    marked = paintLine(marked, x1, y1:y2, [1 0.15 0.05]);
    marked = paintLine(marked, x2, y1:y2, [1 0.15 0.05]);
end

function imageData = paintLine(imageData, xs, ys, color)
    xs = min(max(round(xs), 1), size(imageData, 2));
    ys = min(max(round(ys), 1), size(imageData, 1));
    for dx = -2:2
        for dy = -2:2
            xx = min(max(xs + dx, 1), size(imageData, 2));
            yy = min(max(ys + dy, 1), size(imageData, 1));
            for channel = 1:3
                imageData(yy, xx, channel) = color(channel);
            end
        end
    end
end

function values = normalize01(values)
    values = double(values);
    lo = min(values(:));
    hi = max(values(:));
    values = (values - lo) ./ max(hi - lo, eps);
end

function resetDir(folder)
    if exist(folder, "dir") == 7
        rmdir(folder, "s");
    end
    mkdir(folder);
end

function ensureDir(folder)
    if exist(folder, "dir") ~= 7
        mkdir(folder);
    end
end

function prepareFigure(fig)
    if isempty(fig) || ~isvalid(fig)
        return;
    end
    fig.Position = [100 100 1480 900];
    drawnow;
    pause(0.8);
end

function closeIfValid(fig)
    if ~isempty(fig) && isvalid(fig)
        close(fig);
        drawnow;
    end
end
