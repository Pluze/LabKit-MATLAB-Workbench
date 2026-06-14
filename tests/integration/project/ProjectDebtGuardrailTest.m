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

        end

        function oversizedAppEntrypointDebtIsRemoved(testCase)
            root = setupLabKitTestPath();
            actual = collectOversizedEntrypoints(root, 500);
            testCase.verifyEmpty(actual, ...
                ['app entrypoints must remain at or below 500 lines. Files: ' ...
                strjoin(cellstr(actual), ', ')]);
        end

        function oversizedRunnerDebtIsRemoved(testCase)
            root = setupLabKitTestPath();
            actualFiles = collectOversizedAppRunners(root, 500);
            testCase.verifyTrue(isempty(actualFiles), ...
                ['oversized app runners must not remain. ' ...
                'Split deterministic behavior into app-owned +ops/+view/+export/+io/+state ' ...
                'before moving runner bodies. Files: ' strjoin(cellstr(actualFiles), ', ')]);
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
        end

        function appPrivateRunnerDebtIsRemoved(testCase)
            root = setupLabKitTestPath();
            actualDirs = collectAppPrivateDirs(root);
            testCase.verifyTrue(isempty(actualDirs), ...
                ['app private helper directories are not allowed. Files: ' ...
                strjoin(cellstr(actualDirs), ', ')]);

            actualFiles = collectAppPrivateMFiles(root);
            testCase.verifyTrue(isempty(actualFiles), ...
                ['app private helper debt must not remain. Files: ' ...
                strjoin(cellstr(actualFiles), ', ')]);
        end

        function wearableMigrationTargetUsesAppSubfolder(testCase)
            root = setupLabKitTestPath();
            directPackages = collectDirectPackageDirs( ...
                fullfile(root, 'apps', 'wearable'), root);

            testCase.verifyTrue(isempty(directPackages), ...
                ['Wearable app-owned helpers should live under ' ...
                'apps/wearable/<app_slug>/+<app_slug>, not a direct family ' ...
                'package. Files: ' strjoin(cellstr(directPackages), ', ')]);

            ecgFolder = fullfile(root, 'apps', 'wearable', 'ecg_print');
            if isfolder(ecgFolder)
                testCase.verifyTrue(isfile(fullfile(ecgFolder, ...
                    'labkit_ECGPrint_app.m')), ...
                    'ECG Print migration target should keep the public app entrypoint inside apps/wearable/ecg_print.');
                testCase.verifyTrue(isfolder(fullfile(ecgFolder, '+ecg_print')), ...
                    'ECG Print migration target should use apps/wearable/ecg_print/+ecg_print.');
            end
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
        end

        function appUiRunnersAreNotUsedForAppLifecycle(testCase)
            root = setupLabKitTestPath();
            uiRunners = collectRelativeFiles(root, ...
                fullfile(root, 'apps', '**', '+ui', 'runApp.m'));
            testCase.verifyTrue(isempty(uiRunners), ...
                ['App lifecycle runners belong at package root run.m, not ' ...
                '+ui/runApp.m. Files: ' strjoin(cellstr(uiRunners), ', ')]);
        end

        function dicWearableMigrationsHaveDirectPackageTests(testCase)
            root = setupLabKitTestPath();
            packageRoots = collectDicWearableAppPackageRoots(root);
            missing = strings(numel(packageRoots), 1);
            missingCount = 0;

            for k = 1:numel(packageRoots)
                packageRoot = packageRoots(k);
                nonUiComponents = collectNonUiPackageComponents(packageRoot);
                [family, namespace] = appPackageFamilyAndNamespace(root, packageRoot);
                if isempty(nonUiComponents)
                    missingCount = missingCount + 1;
                    missing(missingCount) = string(relativePath(root, packageRoot)) + ...
                        " -> missing non-UI package component";
                    continue;
                end

                if ~packageNamespaceHasDirectUnitTest(root, family, namespace)
                    missingCount = missingCount + 1;
                    missing(missingCount) = string(relativePath(root, packageRoot)) + ...
                        " -> missing direct unit test for " + namespace + ...
                        ".(ops|view|export|io|state)";
                end
            end
            missing = missing(1:missingCount);

            testCase.verifyTrue(isempty(missing), ...
                ['DIC and wearable app package migrations need directly tested ' ...
                'non-UI app-owned functions; GUI structural tests alone do not prove ' ...
                'runner complexity was reduced. Findings: ' ...
                strjoin(cellstr(missing), ', ')]);
        end
    end
end

function files = uniqueMatchedFiles(root, scopes, pattern)
    matchesByScope = cell(numel(scopes), 1);
    for s = 1:numel(scopes)
        scopeRoot = fullfile(root, scopes{s});
        if isfile(scopeRoot)
            textFiles = {scopeRoot};
        elseif isfolder(scopeRoot)
            textFiles = collectTextFiles(scopeRoot);
        else
            continue;
        end
        matches = strings(numel(textFiles), 1);
        matchCount = 0;
        for k = 1:numel(textFiles)
            content = fileread(textFiles{k});
            if ~isempty(regexp(content, pattern, 'once'))
                matchCount = matchCount + 1;
                matches(matchCount) = string(relativePath(root, textFiles{k}));
            end
        end
        matchesByScope{s} = matches(1:matchCount);
    end
    if isempty(matchesByScope)
        files = strings(1, 0);
    else
        files = unique(vertcat(matchesByScope{:}));
    end
end

function files = collectTextFiles(folder)
    entries = dir(fullfile(folder, '**', '*'));
    entries = entries(~[entries.isdir]);
    if isempty(entries)
        files = {};
        return;
    end
    names = {entries.name};
    keep = endsWith(names, {'.m', '.md', '.ps1', '.sh', '.yml', '.yaml'});
    files = fullfile({entries(keep).folder}, {entries(keep).name});
    files = sort(files);
end

function dirs = collectAppPrivateDirs(root)
    dirs = collectPrivateDirs(fullfile(root, 'apps'), root);
end

function dirs = collectPrivateDirs(folder, root)
    if ~isfolder(folder)
        dirs = strings(1, 0);
        return;
    end

    entries = dir(fullfile(folder, '**', 'private'));
    entries = entries([entries.isdir]);
    if isempty(entries)
        dirs = strings(1, 0);
        return;
    end
    paths = fullfile({entries.folder}, {entries.name});
    dirs = unique(string(relativePaths(root, paths)));
end

function files = collectAppPrivateMFiles(root)
    files = collectRelativeFiles(root, fullfile(root, 'apps', '**', 'private', '*.m'));
end

function dirs = collectDirectPackageDirs(folder, root)
    entries = dir(fullfile(folder, '+*'));
    dirs = strings(numel(entries), 1);
    dirCount = 0;
    for k = 1:numel(entries)
        if entries(k).isdir
            dirCount = dirCount + 1;
            dirs(dirCount) = string(relativePath(root, ...
                fullfile(entries(k).folder, entries(k).name)));
        end
    end
    dirs = unique(dirs(1:dirCount));
end

function files = collectOversizedAppRunners(root, maxLines)
    entries = [ ...
        dir(fullfile(root, 'apps', '**', 'private', 'run*App.m')); ...
        dir(fullfile(root, 'apps', '**', '+*', 'run.m'))];
    files = strings(numel(entries), 1);
    fileCount = 0;
    for k = 1:numel(entries)
        if entries(k).isdir
            continue;
        end
        filepath = fullfile(entries(k).folder, entries(k).name);
        if countFileLines(filepath) > maxLines
            fileCount = fileCount + 1;
            files(fileCount) = string(relativePath(root, filepath));
        end
    end
    files = unique(files(1:fileCount));
end

function files = collectRelativeFiles(root, pattern)
    entries = dir(pattern);
    files = strings(numel(entries), 1);
    fileCount = 0;
    for k = 1:numel(entries)
        if ~entries(k).isdir
            fileCount = fileCount + 1;
            files(fileCount) = string(relativePath(root, ...
                fullfile(entries(k).folder, entries(k).name)));
        end
    end
    files = unique(files(1:fileCount));
end

function packageRoots = collectDicWearableAppPackageRoots(root)
    families = ["dic", "wearable"];
    packageRootsByFamily = cell(numel(families), 1);
    for iFamily = 1:numel(families)
        family = families(iFamily);
        familyRoot = fullfile(root, 'apps', char(family));
        if ~isfolder(familyRoot)
            continue;
        end

        apps = dir(familyRoot);
        appNames = {apps.name};
        appDirs = apps([apps.isdir] & ~ismember(appNames, {'.', '..', 'private'}));
        rootsByApp = cell(numel(appDirs), 1);
        for iApp = 1:numel(appDirs)
            appDir = appDirs(iApp);
            packageDirs = dir(fullfile(appDir.folder, appDir.name, '+*'));
            roots = strings(numel(packageDirs), 1);
            rootCount = 0;
            for iPackage = 1:numel(packageDirs)
                packageDir = packageDirs(iPackage);
                if packageDir.isdir && startsWith(packageDir.name, '+')
                    rootCount = rootCount + 1;
                    roots(rootCount) = string(fullfile( ...
                        packageDir.folder, packageDir.name));
                end
            end
            rootsByApp{iApp} = roots(1:rootCount);
        end
        packageRootsByFamily{iFamily} = vertcat(rootsByApp{:});
    end
    packageRoots = vertcat(packageRootsByFamily{:});
    packageRoots = unique(packageRoots);
end

function components = collectNonUiPackageComponents(packageRoot)
    componentNames = ["+ops", "+view", "+export", "+io", "+state"];
    components = strings(numel(componentNames), 1);
    componentCount = 0;
    for k = 1:numel(componentNames)
        componentRoot = fullfile(packageRoot, char(componentNames(k)));
        files = dir(fullfile(componentRoot, '*.m'));
        if isfolder(componentRoot) && any(~[files.isdir])
            componentCount = componentCount + 1;
            components(componentCount) = componentNames(k);
        end
    end
    components = components(1:componentCount);
end

function [family, namespace] = appPackageFamilyAndNamespace(root, packageRoot)
    rel = string(relativePath(root, char(packageRoot)));
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

function actual = collectOversizedEntrypoints(root, maxLines)
    appFiles = dir(fullfile(root, 'apps', '**', 'labkit_*_app.m'));
    actual = strings(numel(appFiles), 1);
    actualCount = 0;
    for k = 1:numel(appFiles)
        filepath = fullfile(appFiles(k).folder, appFiles(k).name);
        lineCount = countFileLines(filepath);
        if lineCount > maxLines
            actualCount = actualCount + 1;
            actual(actualCount) = string(relativePath(root, filepath));
        end
    end
    actual = actual(1:actualCount);
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

function paths = relativePaths(root, filepaths)
    paths = cell(size(filepaths));
    for k = 1:numel(filepaths)
        paths{k} = relativePath(root, filepaths{k});
    end
end
