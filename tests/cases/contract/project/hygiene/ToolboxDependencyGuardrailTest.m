classdef ToolboxDependencyGuardrailTest < matlab.unittest.TestCase
    %TOOLBOXDEPENDENCYGUARDRAILTEST Guard base-MATLAB compatibility.

    methods (Test, TestTags = {'Integration', 'Style'})
        function appAndFacadeSourceAvoidsHardToolboxDependencies(testCase)
            root = setupLabKitTestPath();
            files = trackedSourceFiles(root);
            actual = unexpectedHardToolboxCalls( ...
                collectHardToolboxCalls(root, files), labkitToolboxDebt());
            testCase.verifyEmpty(actual, ...
                ['apps, LabKit facades, and maintainer scripts must not hard-depend on non-base ' ...
                'MATLAB toolbox helpers unless an exact temporary debt entry ' ...
                'names the source, symbol, product, owner, fallback test, ' ...
                'parity test, and replacement. Never hide dependencies from ' ...
                'the scanner. Findings: ' ...
                strjoin(cellstr(actual), ', ')]);
        end

        function sourceDependenciesResolveToBaseMatlab(testCase)
            testCase.assumeEqual(string(getenv("LABKIT_VERIFY_TOOLBOX_PRODUCTS")), "1", ...
                "Product ownership scan runs through buildtool baseMatlab.");
            root = setupLabKitTestPath();
            files = trackedSourceFiles(root);
            findings = dependencyProductFindings(root, files, labkitToolboxDebt());
            testCase.verifyEmpty(findings, ...
                ["Each source ownership domain must resolve only to MATLAB or " + ...
                "an exact declared temporary toolbox debt. " + ...
                "Findings: " + strjoin(findings, ", ")]);
        end

        function declaredToolboxDebtIsTraceable(testCase)
            root = setupLabKitTestPath();
            findings = toolboxDebtTraceabilityFindings(root, labkitToolboxDebt());
            testCase.verifyEmpty(findings, ...
                ["Every temporary toolbox dependency must be exact, have a " + ...
                "resolvable fallback test, and remain active in the migration " + ...
                "ledger until its app-owned replacement retires it. Findings: " + ...
                strjoin(findings, ", ")]);
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
                "apps/example/run.m:imresize:1"
                "apps/example/run.m:fitcsvm:2"
                "apps/example/run.m:imresize:4"
                "+labkit/+image/helper.m:optimoptions:1"
            ]);
        end

        function debtDeclarationAllowsOnlyExactSourceAndSymbol(testCase)
            findings = [
                "apps/example/run.m:fitcsvm:2"
                "apps/example/run.m:imresize:4"
                "apps/other/run.m:fitcsvm:8"];
            debt = struct('source', "apps/example/run.m", 'symbol', "fitcsvm");
            actual = unexpectedHardToolboxCalls(findings, debt);
            testCase.verifyEqual(actual(:), [
                "apps/example/run.m:imresize:4"
                "apps/other/run.m:fitcsvm:8"]);
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
                ['Rec.601 luma weights should be owned by labkit.image.rgb2gray ' ...
                'instead of copied into app or test code. Findings: ' ...
                strjoin(cellstr(findings), ', ')]);
        end
    end
end

function smokeLabkitImageFacade()
    imageData = uint8(repmat(reshape(0:15, 4, 4), 1, 1, 3));
    rgb = labkit.image.ensureRgb(labkit.image.im2double(imageData));
    luma = labkit.image.rgb2gray(rgb);
    resized = labkit.image.resizeToFit(rgb, "MaxHeight", 2);
    assert(isequal(size(rgb), [4 4 3]), ...
        'Explicit image conversion and RGB shaping should return RGB double data.');
    assert(isequal(size(luma), [4 4]), ...
        'labkit.image.rgb2gray should return one luminance plane.');
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
        if file == "+labkit/+image/rgb2gray.m" || ...
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
    pattern = ['(^|[^\w.])(' char(strjoin(names, "|")) ')\s*\('];
    for k = 1:numel(files)
        file = slashPath(files(k));
        if ~isKey(contents, char(files(k)))
            continue;
        end
        lines = contents(char(files(k)));
        for iLine = 1:numel(lines)
            line = string(lines(iLine));
        trimmed = strtrim(line);
        if startsWith(trimmed, "%") || startsWith(trimmed, "function") || ...
                isempty(regexp(char(line), pattern, 'once'))
                continue;
            end
            tokens = regexp(char(line), pattern, 'tokens', 'once');
            symbol = string(tokens{2});
            findings(end + 1) = file + ":" + symbol + ":" + string(iLine);
        end
    end
end

function findings = unexpectedHardToolboxCalls(findings, debt)
    for iDebt = 1:numel(debt)
        prefix = slashPath(debt(iDebt).source) + ":" + ...
            string(debt(iDebt).symbol) + ":";
        findings(startsWith(findings, prefix)) = [];
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
        "drawrectangle", "poly2mask", "imshow", "cpselect", ...
        "rgb2gray", "rgb2lab", "lab2rgb", "im2double", "imcrop", ...
        "affine2d", "procrustes", ...
        "bwlabel", "regionprops", "graythresh", "imbinarize", "medfilt2", ...
        "fspecial", "imfilter", ...
        "fitcsvm", "fitcecoc", "fitcknn", "fitctree", "fitlm", "fitnlm", ...
        "pca", "kmeans", ...
        "findpeaks", "butter", "filtfilt", "designfilt", "spectrogram", "cwt", ...
        "parpool", "gpuArray", "optimoptions", "fmincon", "lsqcurvefit", "lsqnonlin"];
end

function findings = dependencyProductFindings(root, files, debt)
    groups = [ ...
        "+labkit"
        "apps/dic/dic_preprocess"
        "apps/dic/dic_postprocess"
        "apps/electrochem"
        "apps/gait"
        "apps/image_measurement"
        "apps/labkit_core"
        "apps/neurophysiology"
        "apps/wearable"
        "docs/tools"];
    findings = strings(1, 0);
    assigned = false(size(files));
    for iGroup = 1:numel(groups)
        inGroup = startsWith(files, groups(iGroup) + "/");
        assigned = assigned | inGroup;
        if ~any(inGroup)
            continue;
        end
        absoluteFiles = fullfile(root, files(inGroup));
        [~, products] = matlab.codetools.requiredFilesAndProducts( ...
            cellstr(absoluteFiles));
        certain = logical([products.Certain]);
        productNames = string({products.Name});
        nonBase = productNames(certain & productNames ~= "MATLAB");
        inGroupDebt = startsWith(slashPath(string({debt.source})), groups(iGroup) + "/");
        declaredProducts = string({debt(inGroupDebt).product});
        nonBase = setdiff(nonBase, declaredProducts, 'stable');
        for iProduct = 1:numel(nonBase)
            findings(end + 1) = groups(iGroup) + ": " + nonBase(iProduct);
        end
    end
    assert(all(assigned), ...
        'Every tracked source file must belong to a product-ownership scan group.');
end

function findings = toolboxDebtTraceabilityFindings(root, debt)
    findings = strings(1, 0);
    requiredFields = ["id", "source", "symbol", "product", "owner", ...
        "fallbackTest", "idempotencyTest", "parityTest", "replacement"];
    if isempty(debt)
        return;
    end
    if ~all(isfield(debt, cellstr(requiredFields)))
        findings(end + 1) = "registry: missing required fields";
        return;
    end
    ids = string({debt.id});
    if numel(unique(ids)) ~= numel(ids)
        findings(end + 1) = "registry: duplicate debt ids";
    end
    ledger = string(fileread(fullfile(root, '.agents', 'migration_guide.md')));
    for iDebt = 1:numel(debt)
        entry = debt(iDebt);
        values = string({entry.id, entry.source, entry.symbol, entry.product, ...
            entry.owner, entry.fallbackTest, entry.idempotencyTest, ...
            entry.parityTest, entry.replacement});
        if any(strlength(values) == 0)
            findings(end + 1) = "registry entry " + string(iDebt) + ": empty field";
            continue;
        end
        source = fullfile(root, char(entry.source));
        if exist(source, 'file') ~= 2
            findings(end + 1) = string(entry.id) + ": missing source";
        elseif ~contains(string(fileread(source)), string(entry.symbol))
            findings(end + 1) = string(entry.id) + ": symbol absent from source";
        end
        if ~contains(ledger, string(entry.id))
            findings(end + 1) = string(entry.id) + ": missing active ledger record";
        end
        if ~testSelectorExists(entry.fallbackTest)
            findings(end + 1) = string(entry.id) + ": fallback test not found";
        end
        if ~testSelectorExists(entry.idempotencyTest)
            findings(end + 1) = string(entry.id) + ": idempotency test not found";
        end
        if ~testSelectorExists(entry.parityTest)
            findings(end + 1) = string(entry.id) + ": parity test not found";
        end
    end
end

function tf = testSelectorExists(selector)
    try
        tf = ~isempty(matlab.unittest.TestSuite.fromName(char(selector)));
    catch
        tf = false;
    end
end

function cleanupShadowFolder(folder)
    if contains(path, folder)
        rmpath(folder);
    end
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
