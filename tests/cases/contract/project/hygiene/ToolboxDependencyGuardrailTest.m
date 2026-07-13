classdef ToolboxDependencyGuardrailTest < matlab.unittest.TestCase
    %TOOLBOXDEPENDENCYGUARDRAILTEST Guard base-MATLAB compatibility.

    methods (Test, TestTags = {'Integration', 'Style'})
        function appAndFacadeSourceAvoidsHardToolboxDependencies(testCase)
            root = setupLabKitTestPath();
            files = trackedSourceFiles(root);
            actual = collectHardToolboxCalls(root, files);
            testCase.verifyEmpty(actual, ...
                ['apps, LabKit facades, and maintainer scripts must not hard-depend on non-base ' ...
                'MATLAB toolbox helpers. Use LabKit primitives, app-local ' ...
                'base-MATLAB implementations, or explicit optional ' ...
                'toolbox paths with fallback. Findings: ' ...
                strjoin(cellstr(actual), ', ')]);
        end

        function hardDependencyPatternCatchesUnguardedCalls(testCase)
            root = tempname;
            files = ["apps/example/run.m"; "+labkit/+image/helper.m"];
            contents = containers.Map('KeyType', 'char', 'ValueType', 'any');
            contents(char(files(1))) = [
                "out = imresize(imageData, [10 10]);"
                "model = fitcsvm(X, y);"
                "if exist('imresize', 'file') == 2"
                "    fast = imresize(imageData, [10 10]);"
                "end"
            ];
            contents(char(files(2))) = "opts = optimoptions('lsqnonlin');";

            actual = collectHardToolboxCallsFromContents(root, files, contents);

            testCase.verifyEqual(actual(:), [
                "apps/example/run.m:1"
                "apps/example/run.m:2"
                "+labkit/+image/helper.m:1"
            ]);
        end

        function representativeWorkflowsRunWithToolboxHelpersShadowed(testCase)
            root = setupLabKitTestPath();
            shadowFolder = tempname;
            mkdir(shadowFolder);
            cleanupShadow = onCleanup(@() cleanupShadowFolder(shadowFolder));
            writeToolboxShadowFunctions(shadowFolder);
            addpath(shadowFolder, '-begin');

            smokeLabkitImageFacade();
            smokeDicPreprocess();
            smokeDicPostprocess();
            smokeImageMeasurementApps();
            smokeCurvatureOptimizationFallback();

            testCase.verifyTrue(true, ...
                "Representative image workflows should run without toolbox helpers.");
            clear cleanupShadow
            assert(contains(path, root), ...
                'setupLabKitTestPath should keep the repository on the MATLAB path.');
        end

        function rec601LumaWeightsStayCentralized(testCase)
            root = setupLabKitTestPath();
            files = trackedMatlabFiles(root);
            findings = collectRec601LumaWeightCopies(root, files);
            testCase.verifyEmpty(findings, ...
                ['Rec.601 luma weights should be owned by labkit.image.toLuma ' ...
                'instead of copied into app or test code. Findings: ' ...
                strjoin(cellstr(findings), ', ')]);
        end
    end
end

function smokeLabkitImageFacade()
    imageData = uint8(repmat(reshape(0:15, 4, 4), 1, 1, 3));
    rgb = labkit.image.toRgbDouble(imageData);
    luma = labkit.image.toLuma(imageData);
    resized = labkit.image.resizeToFit(rgb, "MaxHeight", 2);
    assert(isequal(size(rgb), [4 4 3]), ...
        'labkit.image.toRgbDouble should return RGB double image data.');
    assert(isequal(size(luma), [4 4]), ...
        'labkit.image.toLuma should return one luminance plane.');
    assert(size(resized, 1) == 2, ...
        'labkit.image.resizeToFit should use the base-MATLAB resize path.');
end

function smokeDicPreprocess()
    reference = zeros(32, 36);
    reference(8:18, 12:22) = 1;
    moving = zeros(size(reference));
    moving(10:20, 9:19) = 1;
    [aligned, tformRigid] = dic_preprocess.analysisRun.autoAlignMovingToReference( ...
        reference, moving);
    overlay = dic_preprocess.analysisRun.makeFalseColorOverlay(reference, aligned);
    assert(isequal(size(aligned), size(reference)) && isequal(size(tformRigid), [3 3]), ...
        'DIC preprocess auto alignment should return aligned image and matrix.');
    assert(isequal(size(overlay), [32 36 3]), ...
        'DIC preprocess false-color overlay should stay RGB.');
end

function smokeDicPostprocess()
    reference = uint8(120 .* ones(24, 28, 3));
    strain = peaks(12);
    mask = true(12, 12);
    opts = struct( ...
        'alpha', 0.5, ...
        'sigmaSmooth', 1, ...
        'oversample', 1, ...
        'colorRange', [-6 6], ...
        'colormap', parula(64), ...
        'edgeTrim', 0, ...
        'rgbGain', [1 1 1], ...
        'saturation', 1, ...
        'gamma', 1, ...
        'contrast', 1, ...
        'brightness', 0);
    overlay = dic_postprocess.analysisRun.makeStrainOverlay( ...
        reference, strain, mask, mask, opts);
    assert(isequal(size(overlay), [24 28 3]), ...
        'DIC postprocess overlay generation should stay RGB.');
end

function smokeCurvatureOptimizationFallback()
    theta = linspace(0, pi / 2, 20);
    x = 40 + 15 .* cos(theta);
    y = 30 + 15 .* sin(theta);
    fit = curvature.analysisRun.computeCurvatureFit(x, y, ...
        struct('pixelsPerUnit', 1, 'unit', 'px'), false, 100, [], []);
    assert(isfield(fit, 'ok') && fit.ok && isfield(fit, 'R_px') && fit.R_px > 0, ...
        'Curvature fit should use the base-MATLAB optimization fallback.');
end

function smokeImageMeasurementApps()
    base = repmat(linspace(0, 1, 32), 24, 1);
    rgb = cat(3, base, base .* 0.8, base .* 0.6);
    enhanceStep = image_enhance.analysisRun.makeStep('Subject-preserving enhance', 30, 60, 0);
    enhanced = image_enhance.analysisRun.applyStep(rgb, enhanceStep, []);
    matchStep = image_match.analysisRun.makeStep('Tone only', 40, 40, 0);
    matched = image_match.analysisRun.applyStep(rgb, matchStep, min(1, rgb + 0.1));
    focusResult = focus_stack.analysisRun.computeFocusStack({rgb, fliplr(rgb)}, ...
        struct('focusWindow', 3, 'smoothRadius', 1, 'minConfidence', 0));
    assert(isequal(size(enhanced), size(rgb)) && isequal(size(matched), size(rgb)), ...
        'Image measurement enhancement and match helpers should preserve size.');
    assert(focusResult.ok && isequal(size(focusResult.fused), size(rgb)), ...
        'Focus Stack should compute a fused image without toolbox helpers.');
end

function files = trackedSourceFiles(root)
    [status, output] = system(sprintf('git -C "%s" ls-files apps +labkit docs/tools', root));
    assert(status == 0, 'Could not list tracked app, +labkit, and docs/tool files.');
    files = string(splitlines(strtrim(output)));
    files = files(endsWith(files, ".m"));
end

function files = trackedMatlabFiles(root)
    [status, output] = system(sprintf('git -C "%s" ls-files apps +labkit tests', root));
    assert(status == 0, 'Could not list tracked MATLAB files.');
    files = string(splitlines(strtrim(output)));
    files = files(endsWith(files, ".m"));
end

function findings = collectHardToolboxCalls(root, files)
    contents = containers.Map('KeyType', 'char', 'ValueType', 'any');
    for k = 1:numel(files)
        filepath = fullfile(root, char(files(k)));
        if exist(filepath, 'file') == 2
            contents(char(files(k))) = readlines(filepath);
        end
    end
    findings = collectHardToolboxCallsFromContents(root, files, contents);
end

function findings = collectRec601LumaWeightCopies(root, files)
    findings = strings(1, 0);
    weightPatterns = ["0.2989", "0.5870", "0.1140"];
    for k = 1:numel(files)
        file = slashPath(files(k));
        if file == "+labkit/+image/toLuma.m" || ...
                file == "tests/cases/contract/project/hygiene/ToolboxDependencyGuardrailTest.m"
            continue;
        end
        filepath = fullfile(root, char(files(k)));
        if exist(filepath, 'file') ~= 2
            continue;
        end
        lines = readlines(filepath);
        for iLine = 1:numel(lines)
            line = string(lines(iLine));
            if any(contains(line, weightPatterns))
                findings(end + 1) = file + ":" + string(iLine);
            end
        end
    end
end

function findings = collectHardToolboxCallsFromContents(~, files, contents)
    findings = strings(1, 0);
    names = guardedToolboxFunctionNames();
    pattern = ['(^|[^\w])(' char(strjoin(names, "|")) ')\s*\('];
    for k = 1:numel(files)
        file = slashPath(files(k));
        if ~isKey(contents, char(files(k)))
            continue;
        end
        lines = contents(char(files(k)));
        for iLine = 1:numel(lines)
            line = string(lines(iLine));
            if startsWith(strtrim(line), "%") || isempty(regexp(char(line), pattern, 'once'))
                continue;
            end
            if iLine > 1
                previousLine = string(lines(iLine - 1));
            else
                previousLine = "";
            end
            if isAllowedOptionalToolboxCall(file, line, previousLine)
                continue;
            end
            findings(end + 1) = file + ":" + string(iLine);
        end
    end
end

function tf = isAllowedOptionalToolboxCall(file, line, previousLine)
    line = string(line);
    previousLine = string(previousLine);
    tf = false;
    if contains(line, "exist('") || contains(line, 'exist("') || ...
            contains(previousLine, "exist('") || contains(previousLine, 'exist("')
        tf = true;
        return;
    end
    if contains(file, "apps/image_measurement/focus_stack/") && ...
            any(contains(line, ["imregcorr(", "imref2d(", "imwarp("]))
        tf = true;
        return;
    end
    if contains(file, "apps/image_measurement/batch_crop/") && ...
            contains(line, "imresize(")
        tf = true;
        return;
    end
    if contains(file, "apps/image_measurement/curvature/") && ...
            any(contains(line, ["optimoptions(", "lsqnonlin("]))
        tf = true;
    end
end

function path = slashPath(path)
    path = replace(string(path), "\", "/");
end

function writeToolboxShadowFunctions(folder)
    names = guardedToolboxFunctionNames();
    for k = 1:numel(names)
        filepath = fullfile(folder, char(names(k) + ".m"));
        fid = fopen(filepath, 'w');
        assert(fid > 0, 'Could not write toolbox shadow function: %s', filepath);
        cleaner = onCleanup(@() fclose(fid));
        fprintf(fid, 'function varargout = %s(varargin)\n', char(names(k)));
        fprintf(fid, '%% Test shadow for base-MATLAB compatibility checks.\n');
        fprintf(fid, 'error(''LabKit:Tests:ShadowedToolboxCall'', ');
        fprintf(fid, '''Shadowed toolbox helper was called: %s'');\n', char(names(k)));
        fprintf(fid, 'end\n');
        clear cleaner
    end
end

function names = guardedToolboxFunctionNames()
    names = [ ...
        "imresize", "imgaussfilt", "imregcorr", "imwarp", "imref2d", ...
        "rgb2gray", "im2double", "affine2d", "procrustes", ...
        "bwlabel", "regionprops", "graythresh", "imbinarize", "medfilt2", ...
        "fspecial", "imfilter", ...
        "fitcsvm", "fitcecoc", "fitcknn", "fitctree", "fitlm", "fitnlm", ...
        "pca", "kmeans", ...
        "findpeaks", "butter", "filtfilt", "designfilt", "spectrogram", "cwt", ...
        "parpool", "gpuArray", "optimoptions", "fmincon", "lsqcurvefit", "lsqnonlin"];
end

function cleanupShadowFolder(folder)
    if contains(path, folder)
        rmpath(folder);
    end
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
