classdef ProjectDebtGuardrailTest < matlab.unittest.TestCase
    %PROJECTDEBTGUARDRAILTEST Guardrails for legacy surfaces and expected debt.

    methods (Test, TestTags = {'Integration', 'Style'})
        function legacyTestBackdoorDebtDoesNotGrow(testCase)
            root = setupLabKitTestPath();

            testCommandFiles = uniqueMatchedFiles(root, {'apps', '+labkit'}, ...
                '__labkit_test__');
            testCase.verifyEmpty(testCommandFiles, ...
                ['legacy app test command references must not remain. Files: ' ...
                strjoin(cellstr(testCommandFiles), ', ')]);

            handlerFiles = uniqueMatchedFiles(root, {'apps'}, ...
                'function\s+handlers\s*=\s*\w*[Aa]ppTestHandlers');
            testCase.verifyEmpty(handlerFiles, ...
                ['legacy app test handler functions must not remain. Files: ' ...
                strjoin(cellstr(handlerFiles), ', ')]);

            diagnosticsFiles = uniqueMatchedFiles(root, {'apps'}, ...
                'loadFileDiagnostics|parse\w*LoadDiagnosticsRequest|collectLoadDiagnostics');
            testCase.verifyEmpty(diagnosticsFiles, ...
                ['hidden load diagnostics must not remain. Files: ' ...
                strjoin(cellstr(diagnosticsFiles), ', ')]);

            fprintf('Legacy backdoor inventory: %d test-command files, %d handler files, %d diagnostics files.\n', ...
                numel(testCommandFiles), numel(handlerFiles), numel(diagnosticsFiles));
        end

        function oversizedAppEntrypointDebtIsRemoved(testCase)
            root = setupLabKitTestPath();
            actual = collectOversizedEntrypoints(root, 500);
            testCase.verifyEmpty(actual, ...
                ['app entrypoints must remain at or below 500 lines. Files: ' ...
                strjoin(cellstr(actual), ', ')]);
            fprintf('Entrypoint size debt inventory: %d files over 500 lines.\n', numel(actual));
        end

        function oversizedRunnerDebtDoesNotGrow(testCase)
            root = setupLabKitTestPath();
            expectedFiles = expectedOversizedRunnerDebtFiles();
            actualFiles = collectOversizedAppRunners(root, 500);
            unexpectedFiles = setdiff(actualFiles, expectedFiles);
            testCase.verifyTrue(isempty(unexpectedFiles), ...
                ['expected-debt: oversized app runners should not grow. ' ...
                'Split deterministic behavior into app-owned +ops/+view/+export/+io/+state ' ...
                'before moving runner bodies. Files: ' ...
                strjoin(cellstr(unexpectedFiles), ', ')]);

            fprintf('Oversized runner debt inventory: %d files over 500 lines.\n', ...
                numel(actualFiles));
        end

        function oldRunnerDependenciesAreRemoved(testCase)
            root = setupLabKitTestPath();

            testCase.verifyFalse(isfolder(fullfile(root, 'tests', 'suites')), ...
                'tests/suites must not remain after the official-test migration.');
            testCase.verifyFalse(isfile(fullfile(root, 'tests', 'run_all_tests.m')), ...
                'tests/run_all_tests.m must not remain after the official-test migration.');

            dependencyFiles = uniqueMatchedFiles(root, ...
                {'.github', 'scripts', 'docs', 'tests', 'buildfile.m', ...
                'README.md', 'AGENTS.md', 'apps', '+labkit'}, ...
                'IncludeLegacy|run_all_tests|tests[/\\]suites');
            dependencyFiles = setdiff(dependencyFiles, ...
                "tests/integration/project/ProjectDebtGuardrailTest.m");
            testCase.verifyEmpty(dependencyFiles, ...
                ['old custom-runner dependencies must not remain. Files: ' ...
                strjoin(cellstr(dependencyFiles), ', ')]);

            fprintf('Old runner dependency inventory: %d files.\n', numel(dependencyFiles));
        end

        function appPrivateRunnerDebtDoesNotGrow(testCase)
            root = setupLabKitTestPath();
            expectedDirs = [ ...
                "apps/dic/private", ...
                "apps/wearable/private"];
            actualDirs = collectAppPrivateDirs(root);
            unexpectedDirs = setdiff(actualDirs, expectedDirs);
            testCase.verifyTrue(isempty(unexpectedDirs), ...
                ['expected-debt: new app private helper directories are not allowed. Files: ' ...
                strjoin(cellstr(unexpectedDirs), ', ')]);

            expectedFiles = expectedAppPrivateDebtFiles();
            actualFiles = collectAppPrivateMFiles(root);
            unexpectedFiles = setdiff(actualFiles, expectedFiles);
            testCase.verifyTrue(isempty(unexpectedFiles), ...
                ['expected-debt: app private helper debt grew. Files: ' ...
                strjoin(cellstr(unexpectedFiles), ', ')]);

            fprintf('App private helper debt inventory: %d files in %d directories.\n', ...
                numel(actualFiles), numel(actualDirs));
        end

        function appWorkflowDispatchDebtDoesNotGrow(testCase)
            root = setupLabKitTestPath();
            workflowFiles = collectRelativeFiles(root, ...
                fullfile(root, 'apps', '**', '*Workflow.m'));
            testCase.verifyTrue(isempty(workflowFiles), ...
                ['String-dispatch workflow adapters should not be reintroduced. Files: ' ...
                strjoin(cellstr(workflowFiles), ', ')]);

            dispatchFiles = collectRelativeFiles(root, ...
                fullfile(root, 'apps', '**', '+core', 'dispatch.m'));
            testCase.verifyTrue(isempty(dispatchFiles), ...
                ['App-owned +core/dispatch.m string routers should not exist. Files: ' ...
                strjoin(cellstr(dispatchFiles), ', ')]);

            fprintf('Workflow dispatch debt inventory: %d Workflow files, %d +core dispatch files.\n', ...
                numel(workflowFiles), numel(dispatchFiles));
        end

        function dicWearableMigrationsHaveDirectPackageTests(testCase)
            root = setupLabKitTestPath();
            packageRoots = collectDicWearableAppPackageRoots(root);
            missing = strings(1, 0);

            for k = 1:numel(packageRoots)
                packageRoot = packageRoots(k);
                nonUiComponents = collectNonUiPackageComponents(packageRoot);
                [family, namespace] = appPackageFamilyAndNamespace(root, packageRoot);
                if isempty(nonUiComponents)
                    missing(end+1) = string(relativePath(root, packageRoot)) + ...
                        " -> missing non-UI package component"; %#ok<AGROW>
                    continue;
                end

                if ~packageNamespaceHasDirectUnitTest(root, family, namespace)
                    missing(end+1) = string(relativePath(root, packageRoot)) + ...
                        " -> missing direct unit test for " + namespace + ...
                        ".(ops|view|export|io|state)"; %#ok<AGROW>
                end
            end

            testCase.verifyTrue(isempty(missing), ...
                ['DIC and wearable app package migrations need directly tested ' ...
                'non-UI app-owned functions; GUI structural tests alone do not prove ' ...
                'runner complexity was reduced. Findings: ' ...
                strjoin(cellstr(missing), ', ')]);

            fprintf('DIC/wearable migrated app package inventory: %d package roots.\n', ...
                numel(packageRoots));
        end
    end
end

function files = uniqueMatchedFiles(root, scopes, pattern)
    files = strings(1, 0);
    for s = 1:numel(scopes)
        scopeRoot = fullfile(root, scopes{s});
        if isfile(scopeRoot)
            textFiles = {scopeRoot};
        elseif isfolder(scopeRoot)
            textFiles = collectTextFiles(scopeRoot);
        else
            continue;
        end
        for k = 1:numel(textFiles)
            content = fileread(textFiles{k});
            if ~isempty(regexp(content, pattern, 'once'))
                files(end+1) = string(relativePath(root, textFiles{k})); %#ok<AGROW>
            end
        end
    end
    files = unique(files);
end

function files = collectTextFiles(folder)
    files = {};
    entries = dir(folder);
    [~, order] = sort({entries.name});
    entries = entries(order);
    for k = 1:numel(entries)
        entry = entries(k);
        if entry.isdir
            if any(strcmp(entry.name, {'.', '..'}))
                continue;
            end
            files = [files, collectTextFiles(fullfile(folder, entry.name))]; %#ok<AGROW>
        elseif endsWith(entry.name, {'.m', '.md', '.ps1', '.sh', '.yml', '.yaml'})
            files{end+1} = fullfile(entry.folder, entry.name); %#ok<AGROW>
        end
    end
end

function dirs = collectAppPrivateDirs(root)
    dirs = collectPrivateDirs(fullfile(root, 'apps'), root);
end

function dirs = collectPrivateDirs(folder, root)
    dirs = strings(1, 0);
    if ~isfolder(folder)
        return;
    end

    entries = dir(folder);
    for k = 1:numel(entries)
        entry = entries(k);
        if ~entry.isdir || any(strcmp(entry.name, {'.', '..'}))
            continue;
        end

        child = fullfile(entry.folder, entry.name);
        if strcmp(entry.name, 'private')
            dirs(end+1) = string(relativePath(root, ...
                child)); %#ok<AGROW>
        else
            dirs = [dirs, collectPrivateDirs(child, root)]; %#ok<AGROW>
        end
    end
    dirs = unique(dirs);
end

function files = collectAppPrivateMFiles(root)
    files = collectRelativeFiles(root, fullfile(root, 'apps', '**', 'private', '*.m'));
end

function files = collectOversizedAppRunners(root, maxLines)
    files = strings(1, 0);
    entries = [ ...
        dir(fullfile(root, 'apps', '**', 'private', 'run*App.m')); ...
        dir(fullfile(root, 'apps', '**', '+ui', 'runApp.m'))];
    for k = 1:numel(entries)
        if entries(k).isdir
            continue;
        end
        filepath = fullfile(entries(k).folder, entries(k).name);
        if countFileLines(filepath) > maxLines
            files(end+1) = string(relativePath(root, filepath)); %#ok<AGROW>
        end
    end
    files = unique(files);
end

function files = collectRelativeFiles(root, pattern)
    entries = dir(pattern);
    files = strings(1, 0);
    for k = 1:numel(entries)
        if ~entries(k).isdir
            files(end+1) = string(relativePath(root, ...
                fullfile(entries(k).folder, entries(k).name))); %#ok<AGROW>
        end
    end
    files = unique(files);
end

function packageRoots = collectDicWearableAppPackageRoots(root)
    packageRoots = strings(1, 0);
    families = ["dic", "wearable"];
    for family = families
        familyRoot = fullfile(root, 'apps', char(family));
        if ~isfolder(familyRoot)
            continue;
        end

        apps = dir(familyRoot);
        for iApp = 1:numel(apps)
            appDir = apps(iApp);
            if ~appDir.isdir || any(strcmp(appDir.name, {'.', '..', 'private'}))
                continue;
            end

            packageDirs = dir(fullfile(appDir.folder, appDir.name, '+*'));
            for iPackage = 1:numel(packageDirs)
                packageDir = packageDirs(iPackage);
                if packageDir.isdir && startsWith(packageDir.name, '+')
                    packageRoots(end+1) = string(fullfile( ...
                        packageDir.folder, packageDir.name)); %#ok<AGROW>
                end
            end
        end
    end
    packageRoots = unique(packageRoots);
end

function components = collectNonUiPackageComponents(packageRoot)
    components = strings(1, 0);
    componentNames = ["+ops", "+view", "+export", "+io", "+state"];
    for k = 1:numel(componentNames)
        componentRoot = fullfile(packageRoot, char(componentNames(k)));
        files = dir(fullfile(componentRoot, '*.m'));
        if isfolder(componentRoot) && any(~[files.isdir])
            components(end+1) = componentNames(k); %#ok<AGROW>
        end
    end
end

function [family, namespace] = appPackageFamilyAndNamespace(root, packageRoot)
    rel = string(relativePath(root, packageRoot));
    parts = split(rel, '/');
    family = parts(2);
    packageName = parts(end);
    namespace = extractAfter(packageName, 1);
end

function tf = packageNamespaceHasDirectUnitTest(root, family, namespace)
    testRoot = fullfile(root, 'tests', 'unit', 'apps', char(family));
    if ~isfolder(testRoot)
        tf = false;
        return;
    end

    pattern = [char(namespace) '\.(ops|view|export|io|state)\.'];
    testFiles = collectTextFiles(testRoot);
    tf = false;
    for k = 1:numel(testFiles)
        if ~isempty(regexp(fileread(testFiles{k}), pattern, 'once'))
            tf = true;
            return;
        end
    end
end

function files = expectedAppPrivateDebtFiles()
    files = [ ...
        "apps/dic/private/alignMovingToReference.m", ...
        "apps/dic/private/autoAlignMovingToReference.m", ...
        "apps/dic/private/axesImageSize.m", ...
        "apps/dic/private/boundaryMaskImage.m", ...
        "apps/dic/private/catmullRomPoint.m", ...
        "apps/dic/private/chooseImageFile.m", ...
        "apps/dic/private/clamp01.m", ...
        "apps/dic/private/clampLimits.m", ...
        "apps/dic/private/colorbarLevelsTable.m", ...
        "apps/dic/private/cropSelectionSummary.m", ...
        "apps/dic/private/cropSummary.m", ...
        "apps/dic/private/defaultSquareRect.m", ...
        "apps/dic/private/deleteIfValid.m", ...
        "apps/dic/private/displayPath.m", ...
        "apps/dic/private/enhanceReferenceImage.m", ...
        "apps/dic/private/ensureRgb.m", ...
        "apps/dic/private/exportOverlayFigure.m", ...
        "apps/dic/private/exportStrainColorbar.m", ...
        "apps/dic/private/extendStrainMapToRoi.m", ...
        "apps/dic/private/imageHeightWidth.m", ...
        "apps/dic/private/imageMask.m", ...
        "apps/dic/private/insideImageBounds.m", ...
        "apps/dic/private/loadNcorrStrain.m", ...
        "apps/dic/private/makeFalseColorOverlay.m", ...
        "apps/dic/private/makeStrainOverlay.m", ...
        "apps/dic/private/maskBoundaryCurve.m", ...
        "apps/dic/private/maskFromCurve.m", ...
        "apps/dic/private/maskRgb.m", ...
        "apps/dic/private/nanSafeStats.m", ...
        "apps/dic/private/normalizeGray.m", ...
        "apps/dic/private/runDICPreprocessApp.m", ...
        "apps/dic/private/showImage.m", ...
        "apps/dic/private/squareRectInsideImage.m", ...
        "apps/dic/private/strainToRgb.m", ...
        "apps/dic/private/strainValidMask.m", ...
        "apps/dic/private/summarizeStrain.m", ...
        "apps/dic/private/summaryMaskForStrain.m", ...
        "apps/dic/private/summaryTableData.m", ...
        "apps/dic/private/tagFromPath.m", ...
        "apps/dic/private/ternary.m", ...
        "apps/dic/private/transformMatrix.m", ...
        "apps/dic/private/transformSummary.m", ...
        "apps/dic/private/wrapIndex.m", ...
        "apps/dic/private/zoomAxesAtPoint.m", ...
        "apps/wearable/private/runECGPrintApp.m"];
end

function files = expectedOversizedRunnerDebtFiles()
    files = [ ...
        "apps/dic/private/runDICPreprocessApp.m", ...
        "apps/electrochem/cic/+cic/+ui/runApp.m", ...
        "apps/electrochem/csc/+csc/+ui/runApp.m", ...
        "apps/electrochem/eis/+eis/+ui/runApp.m", ...
        "apps/wearable/private/runECGPrintApp.m"];
end

function assertExpectedDebt(testCase, actualFiles, expectedMax, label)
    testCase.verifyTrue(numel(actualFiles) <= expectedMax, ...
        sprintf('%s. Current count %d exceeds expected debt %d. Files: %s', ...
        label, numel(actualFiles), expectedMax, strjoin(cellstr(actualFiles), ', ')));
end

function actual = collectOversizedEntrypoints(root, maxLines)
    appFiles = dir(fullfile(root, 'apps', '**', 'labkit_*_app.m'));
    actual = strings(1, 0);
    for k = 1:numel(appFiles)
        filepath = fullfile(appFiles(k).folder, appFiles(k).name);
        lineCount = countFileLines(filepath);
        if lineCount > maxLines
            actual(end+1) = string(relativePath(root, filepath)); %#ok<AGROW>
        end
    end
end

function n = countFileLines(filepath)
    n = numel(readlines(filepath));
end

function rel = relativePath(root, filepath)
    rel = filepath;
    prefix = [root filesep];
    if startsWith(filepath, prefix)
        rel = filepath(numel(prefix)+1:end);
    end
    rel = strrep(rel, filesep, '/');
end
