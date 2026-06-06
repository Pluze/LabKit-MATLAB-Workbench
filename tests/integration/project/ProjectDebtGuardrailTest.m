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
            staleFiles = setdiff(expectedFiles, actualFiles);
            testCase.verifyTrue(isempty(unexpectedFiles), ...
                ['expected-debt: oversized app runners should not grow. ' ...
                'Split deterministic behavior into app-owned +ops/+view/+export/+io/+state ' ...
                'before moving runner bodies. Files: ' ...
                strjoin(cellstr(unexpectedFiles), ', ')]);
            testCase.verifyTrue(isempty(staleFiles), ...
                ['expected-debt: oversized app runner inventory includes ' ...
                'resolved files. Remove them from expectedOversizedRunnerDebtFiles: ' ...
                strjoin(cellstr(staleFiles), ', ')]);

            fprintf('Oversized runner debt inventory: %d files over 500 lines.\n', ...
                numel(actualFiles));
        end

        function oversizedRunnersHaveMigrationMaps(testCase)
            root = setupLabKitTestPath();
            actualFiles = collectOversizedAppRunners(root, 500);
            mapFile = fullfile(root, '.agents', 'migration_guide.md');
            testCase.assertTrue(isfile(mapFile), ...
                '.agents/migration_guide.md should track every oversized runner.');

            mappedFiles = collectRunnerMigrationMapFiles(mapFile);
            missingFiles = setdiff(actualFiles, mappedFiles);
            staleFiles = setdiff(mappedFiles, actualFiles);

            testCase.verifyTrue(isempty(missingFiles), ...
                ['Oversized app runners need migration maps. Files: ' ...
                strjoin(cellstr(missingFiles), ', ')]);
            testCase.verifyTrue(isempty(staleFiles), ...
                ['Runner migration maps include resolved or non-oversized files. ' ...
                'Remove or update these headings: ' strjoin(cellstr(staleFiles), ', ')]);
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
            expectedDirs = strings(1, 0);
            actualDirs = collectAppPrivateDirs(root);
            unexpectedDirs = setdiff(actualDirs, expectedDirs);
            staleDirs = setdiff(expectedDirs, actualDirs);
            testCase.verifyTrue(isempty(unexpectedDirs), ...
                ['expected-debt: new app private helper directories are not allowed. Files: ' ...
                strjoin(cellstr(unexpectedDirs), ', ')]);
            testCase.verifyTrue(isempty(staleDirs), ...
                ['expected-debt: app private helper directory inventory includes ' ...
                'resolved directories. Remove them from expectedDirs: ' ...
                strjoin(cellstr(staleDirs), ', ')]);

            expectedFiles = expectedAppPrivateDebtFiles();
            actualFiles = collectAppPrivateMFiles(root);
            unexpectedFiles = setdiff(actualFiles, expectedFiles);
            staleFiles = setdiff(expectedFiles, actualFiles);
            testCase.verifyTrue(isempty(unexpectedFiles), ...
                ['expected-debt: app private helper debt grew. Files: ' ...
                strjoin(cellstr(unexpectedFiles), ', ')]);
            testCase.verifyTrue(isempty(staleFiles), ...
                ['expected-debt: app private helper inventory includes resolved files. ' ...
                'Remove them from expectedAppPrivateDebtFiles: ' ...
                strjoin(cellstr(staleFiles), ', ')]);

            fprintf('App private helper debt inventory: %d files in %d directories.\n', ...
                numel(actualFiles), numel(actualDirs));
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

            fprintf('Workflow dispatch debt inventory: %d Workflow files, %d +core dispatch files.\n', ...
                numel(workflowFiles), numel(dispatchFiles));
        end

        function appUiRunnersDoNotShadowExtractedPackageHelpers(testCase)
            root = setupLabKitTestPath();
            runners = collectRelativeFiles(root, ...
                fullfile(root, 'apps', '**', '+ui', 'runApp.m'));
            findings = strings(1, 0);

            for k = 1:numel(runners)
                runnerPath = fullfile(root, strrep(runners(k), '/', filesep));
                packageRoot = owningPackageRootForRunner(runnerPath);
                if strlength(packageRoot) == 0
                    continue;
                end

                runnerFunctions = setdiff(functionNamesInFile(runnerPath), "runApp");
                packageFunctions = packageComponentFunctionNames(packageRoot);
                overlap = intersect(runnerFunctions, packageFunctions);
                if ~isempty(overlap)
                    findings(end+1) = runners(k) + " -> " + ...
                        strjoin(overlap, ", "); %#ok<AGROW>
                end
            end

            testCase.verifyTrue(isempty(findings), ...
                ['App UI runners should call extracted app-owned package helpers, ' ...
                'not keep same-named local copies. Findings: ' ...
                strjoin(cellstr(findings), ', ')]);
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

function dirs = collectDirectPackageDirs(folder, root)
    entries = dir(fullfile(folder, '+*'));
    dirs = strings(1, 0);
    for k = 1:numel(entries)
        if entries(k).isdir
            dirs(end+1) = string(relativePath(root, ...
                fullfile(entries(k).folder, entries(k).name))); %#ok<AGROW>
        end
    end
    dirs = unique(dirs);
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

function files = collectRunnerMigrationMapFiles(mapFile)
    content = fileread(mapFile);
    tokens = regexp(content, '(?m)^## `([^`]+)`\s*$', 'tokens');
    files = strings(1, 0);
    for k = 1:numel(tokens)
        files(end+1) = string(tokens{k}{1}); %#ok<AGROW>
    end
    files = unique(files);
end

function packageRoot = owningPackageRootForRunner(runnerPath)
    uiDir = fileparts(runnerPath);
    packageRoot = string(fileparts(uiDir));
    [~, packageName] = fileparts(char(packageRoot));
    if ~startsWith(packageName, '+')
        packageRoot = "";
    end
end

function names = packageComponentFunctionNames(packageRoot)
    components = ["+ops", "+view", "+export", "+io", "+state"];
    names = strings(1, 0);
    for k = 1:numel(components)
        componentRoot = fullfile(packageRoot, components(k));
        files = dir(fullfile(componentRoot, '*.m'));
        for iFile = 1:numel(files)
            [~, name] = fileparts(files(iFile).name);
            names(end+1) = string(name); %#ok<AGROW>
        end
    end
    names = unique(names);
end

function names = functionNamesInFile(filepath)
    content = fileread(filepath);
    withOutput = regexp(content, ...
        '(?m)^\s*function\s+(?:\[[^\]]+\]|\w+)\s*=\s*(\w+)\s*\(', ...
        'tokens');
    withoutOutput = regexp(content, ...
        '(?m)^\s*function\s+(\w+)\s*\(', ...
        'tokens');
    names = strings(1, 0);
    for k = 1:numel(withOutput)
        names(end+1) = string(withOutput{k}{1}); %#ok<AGROW>
    end
    for k = 1:numel(withoutOutput)
        names(end+1) = string(withoutOutput{k}{1}); %#ok<AGROW>
    end
    names = unique(names);
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

function files = expectedAppPrivateDebtFiles()
    files = strings(1, 0);
end

function files = expectedOversizedRunnerDebtFiles()
    files = [ ...
        "apps/electrochem/cic/+cic/+ui/runApp.m", ...
        "apps/electrochem/csc/+csc/+ui/runApp.m"];
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
