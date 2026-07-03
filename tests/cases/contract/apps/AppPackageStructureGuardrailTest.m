classdef AppPackageStructureGuardrailTest < matlab.unittest.TestCase
    %APPPACKAGESTRUCTUREGUARDRAILTEST Guardrails for app package layout.

    methods (Test, TestTags = {'Integration', 'Style'})
        function supportedAppsUseCanonicalAppPackageStructure(testCase)
            root = setupLabKitTestPath();
            specs = discoveredAppSpecs(root);
            testCase.assertFalse(isempty(specs), ...
                'App package structure guardrail should discover app entrypoints.');

            for k = 1:size(specs, 1)
                assertCanonicalAppPackageStructure(testCase, root, ...
                    specs{k, 1}, specs{k, 2}, specs{k, 3});
            end
        end

        function appFoldersDoNotMixFileAndFolderForms(testCase)
            root = setupLabKitTestPath();
            specs = discoveredAppSpecs(root);
            for k = 1:size(specs, 1)
                appDir = fullfile(root, specs{k, 1});
                assertNoSameStemFileFolder(testCase, root, appDir);
                packageName = specs{k, 2};
                if strlength(string(packageName)) > 0
                    assertNoSameStemFileFolder(testCase, root, ...
                        fullfile(appDir, ['+' packageName]));
                end
            end
        end

        function imageWorkflowAppsKeepTaskLifecycleSnapshots(testCase)
            root = setupLabKitTestPath();
            expected = [
                "apps/image_measurement/image_enhance/+image_enhance/+appState/exportTask.m"
                "apps/image_measurement/image_match/+image_match/+appState/exportTask.m"
                "apps/image_measurement/batch_crop/+batch_crop/+appState/exportPlan.m"
                "apps/image_measurement/focus_stack/+focus_stack/+appState/runTask.m"
                "apps/image_measurement/curvature/+curvature/+appState/fitTask.m"
                "apps/image_measurement/curvature/+curvature/+appState/lengthTask.m"];

            for k = 1:numel(expected)
                filepath = repoPath(root, expected(k));
                testCase.verifyTrue(isfile(filepath), ...
                    "Image workflow task lifecycle helper is missing: " + expected(k));
                source = string(fileread(filepath));
                testCase.verifyTrue(contains(source, "fingerprint"), ...
                    "Task lifecycle helper should expose a deterministic fingerprint: " + expected(k));
            end

            docs = string(fileread(fullfile(root, "docs", "apps.md")));
            appRules = string(fileread(fullfile(root, "apps", "AGENTS.md")));
            testCase.verifyTrue(contains(docs, "Task Lifecycle"), ...
                "docs/apps.md should document the app-owned task lifecycle boundary.");
            testCase.verifyTrue(contains(appRules, "immutable") && ...
                contains(appRules, "fingerprints"), ...
                "apps/AGENTS.md should preserve the task snapshot/fingerprint rule.");
        end

    end
end

function assertNoSameStemFileFolder(testCase, root, folder)
    if ~isfolder(folder)
        return;
    end
    files = dir(fullfile(folder, '*.m'));
    dirs = dir(folder);
    dirs = dirs([dirs.isdir]);
    dirs = dirs(~ismember({dirs.name}, {'.', '..'}));
    fileStems = erase(string({files.name}), ".m");
    dirStems = erase(string({dirs.name}), "+");
    conflicts = intersect(fileStems, dirStems);
    testCase.verifyTrue(isempty(conflicts), ...
        [relativePath(root, folder) ' mixes file and folder forms for the ' ...
        'same app role: ' strjoin(cellstr(conflicts), ', ')]);
end

function specs = discoveredAppSpecs(root)
    entries = dir(fullfile(root, 'apps', '**', 'labkit_*_app.m'));
    [~, order] = sort(string(fullfile({entries.folder}, {entries.name})));
    entries = entries(order);
    specs = cell(numel(entries), 3);
    for k = 1:numel(entries)
        appDir = entries(k).folder;
        packageDirs = dir(fullfile(appDir, '+*'));
        packageDirs = packageDirs([packageDirs.isdir]);
        packageNames = extractAfter(string({packageDirs.name}), 1);
        packageNames = sort(packageNames);
        if isempty(packageNames)
            packageName = "";
        else
            packageName = char(packageNames(1));
        end
        specs{k, 1} = relativePath(root, appDir);
        specs{k, 2} = packageName;
        specs{k, 3} = entries(k).name;
    end
end

function assertCanonicalAppPackageStructure(testCase, root, appRelDir, packageName, entrypointName)
    appDir = fullfile(root, appRelDir);
    packageDir = fullfile(appDir, ['+' packageName]);
    uiDir = fullfile(packageDir, '+ui');
    userInterfaceDir = fullfile(packageDir, '+userInterface');
    entrypointFile = fullfile(appDir, entrypointName);
    runFile = fullfile(packageDir, 'run.m');
    definitionFile = fullfile(packageDir, 'definition.m');
    buildSpecFile = fullfile(userInterfaceDir, 'buildWorkbenchSpec.m');
    appLabel = relativePath(root, appDir);

    testCase.verifyGreaterThan(strlength(string(packageName)), 0, ...
        ['App entrypoint should have one app-owned package namespace: ' appLabel]);
    testCase.verifyFalse(isfolder(fullfile(appDir, 'private')), ...
        [appLabel ' should use an app-owned package, not private/.']);
    testCase.verifyFalse(isfolder(fullfile(appDir, '+app')), ...
        [appLabel ' should not use a fixed +app namespace.']);
    workflowFiles = dir(fullfile(appDir, '*Workflow.m'));
    testCase.verifyTrue(isempty(workflowFiles), ...
        [appLabel ' should not keep workflow dispatch adapters.']);

    testCase.verifyTrue(isfile(buildSpecFile), ...
        ['Apps must keep the ordinary data-only spec at ' ...
        relativePath(root, buildSpecFile)]);
    testCase.verifyTrue(isfile(entrypointFile), ...
        ['Missing app entrypoint: ' relativePath(root, entrypointFile)]);
    testCase.verifyTrue(isfile(definitionFile), ...
        ['App package must provide a definition runtime: ' ...
        relativePath(root, packageDir)]);
    testCase.verifyFalse(isfile(runFile), ...
        [appLabel ' should not keep package-root run.m orchestration.']);
    testCase.verifyFalse(isfile(fullfile(uiDir, 'runApp.m')), ...
        [appLabel ' should not keep app lifecycle orchestration in +ui/runApp.m.']);
    assertWorkflowFirstPackageShape(testCase, root, packageDir);

    orchestrationSource = appOrchestrationSource(entrypointFile, runFile, ...
        definitionFile);
    usesBuildSpecCall = contains(orchestrationSource, ...
        [packageName '.userInterface.buildWorkbenchSpec(']) || ...
        contains(orchestrationSource, ...
        ['@' packageName '.userInterface.buildWorkbenchSpec']);
    testCase.verifyTrue(usesBuildSpecCall, ...
        [appLabel ' should call its canonical UI spec builder.']);
    testCase.verifyTrue(contains(orchestrationSource, 'labkit.ui.app.run(') && ...
        contains(orchestrationSource, [packageName '.definition()']), ...
        [appLabel ' definitions should launch through labkit.ui.app.run.']);

    buildSpecSource = fileread(buildSpecFile);
    testCase.verifyTrue(contains(buildSpecSource, 'labkit.ui.spec.app'), ...
        [relativePath(root, buildSpecFile) ' should return a UI 3.0 app spec.']);
    assertSourceDoesNotContain(testCase, buildSpecSource, ...
        buildSpecForbiddenWords(), relativePath(root, buildSpecFile));
    assertNoAppOwnedLayoutProps(testCase, buildSpecSource, ...
        relativePath(root, buildSpecFile));
    assertNoEmptyUiSections(testCase, buildSpecSource, ...
        relativePath(root, buildSpecFile));

    packageSource = readPackageSource(packageDir);
    assertSourceDoesNotContain(testCase, packageSource, ...
        appPackageForbiddenWords(), appLabel);
    assertNoGenericHelperNames(testCase, root, packageDir);
    assertRolePackageBoundaries(testCase, root, packageDir);
    family = appFamilyFromRelativeDir(appRelDir);
    assertAppOwnedPackageCapability(testCase, root, appDir, packageDir, ...
        family, packageName);
end

function assertWorkflowFirstPackageShape(testCase, root, packageDir)
    requiredFiles = [
        string(fullfile(packageDir, 'definitionActions.m'))
        string(fullfile(packageDir, '+appLifecycle', 'createInitialState.m'))
        string(fullfile(packageDir, '+userInterface', 'buildWorkbenchSpec.m'))
        string(fullfile(packageDir, '+userInterface', 'updateWorkbenchFromState.m'))];
    for k = 1:numel(requiredFiles)
        testCase.verifyTrue(isfile(requiredFiles(k)), ...
            ['Workflow-first app packages should include ' ...
            relativePath(root, requiredFiles(k))]);
    end

    oldBuckets = ["+actions", "+renderers", "+ops", "+io", "+export", ...
        "+state", "+view", "+ui"];
    conflicts = strings(1, 0);
    for k = 1:numel(oldBuckets)
        candidate = fullfile(packageDir, char(oldBuckets(k)));
        if isfolder(candidate)
            conflicts(end+1) = string(relativePath(root, candidate));
        end
    end
    testCase.verifyTrue(isempty(conflicts), ...
        ['Workflow-first app packages should not reintroduce overlapping ' ...
        'technical role buckets: ' strjoin(cellstr(conflicts), ', ')]);
end

function source = appOrchestrationSource(entrypointFile, runFile, definitionFile)
    parts = {fileread(entrypointFile)};
    if isfile(runFile)
        parts{end + 1} = fileread(runFile);
    end
    if isfile(definitionFile)
        parts{end + 1} = fileread(definitionFile);
    end
    source = strjoin(parts, newline);
end

function words = buildSpecForbiddenWords()
    words = {'uifigure(', 'uigridlayout(', 'uibutton(', 'uilabel(', ...
        'uidropdown(', 'uispinner(', 'uieditfield(', 'uitable(', ...
        'uiaxes(', 'uitextarea(', 'labkit.ui.app.create', ...
        'Layout.Row', 'Layout.Column', 'uigetfile(', 'uigetdir(', ...
        'uiputfile(', 'uialert(', 'writetable(', 'imwrite(', 'S.'};
end

function words = appPackageForbiddenWords()
    words = {'labkit.ui.app.createShell', 'labkit.ui.app.tab(', ...
        'labkit.ui.view.section', 'labkit.ui.view.form', ...
        'labkit.ui.view.panel', 'labkit.ui.view.draw(', ...
        'labkit.ui.view.update(', 'labkit.ui.view.place', ...
        'uigridlayout(', 'Layout.Row', 'Layout.Column', ...
        'createRightAxesPair', 'createEditorUi', 'createUi('};
end

function assertNoAppOwnedLayoutProps(testCase, source, label)
    layoutProps = {'height', 'minRows', 'minHeight', 'maxColumns', ...
        'rowSpacing', 'columnSpacing', 'padding', 'chrome', ...
        'columnWidth', 'rowHeight', 'position', 'leftWidth'};
    matches = strings(1, 0);
    for k = 1:numel(layoutProps)
        prop = layoutProps{k};
        if contains(source, ['''' prop ''',']) || ...
                contains(source, ['"' prop '",'])
            matches(end+1) = string(prop);
        end
    end

    testCase.verifyTrue(isempty(matches), ...
        [label ' declares concrete layout props. Apps may declare pages, ' ...
        'sections, controls, order, semantic values, and callbacks; LabKit ' ...
        'owns concrete layout: ' strjoin(cellstr(matches), ', ')]);
end

function assertNoEmptyUiSections(testCase, source, label)
    matches = regexp(source, ...
        'labkit\.ui\.spec\.section[\s\S]*?\{\s*\}\s*\)', 'match');
    testCase.verifyTrue(isempty(matches), ...
        [label ' declares an empty UI section. Sections should contain ' ...
        'real controls or a semantic toolPanel host; do not leave titled ' ...
        'empty placeholders in app layouts.']);
end

function assertNoGenericHelperNames(testCase, root, packageDir)
    forbidden = {'helpers.m', 'utils.m', 'common.m', 'misc.m', ...
        'functions.m', 'callbacks.m', 'manager.m', 'processor.m', ...
        'newUI.m', 'layout.m', 'layout2.m', 'createUI.m', 'makeUI.m', ...
        'place.m', 'createRightAxesPair.m', 'createEditorUi.m', 'createUi.m'};
    files = dir(fullfile(packageDir, '**', '*.m'));
    bad = strings(1, 0);
    for k = 1:numel(files)
        if any(strcmp(files(k).name, forbidden))
            bad(end+1) = string(relativePath(root, ...
                fullfile(files(k).folder, files(k).name)));
        end
    end

    testCase.verifyTrue(isempty(bad), ...
        ['Migrated app packages should name files by stable role/output, not ' ...
        'generic helper buckets: ' strjoin(cellstr(bad), ', ')]);
end

function assertRolePackageBoundaries(testCase, root, packageDir)
    assertComponentSourcesDoNotContain(testCase, root, fullfile(packageDir, '+ops'), ...
        {'labkit.ui', 'uialert(', 'uigetfile(', 'uigetdir(', ...
        'uiputfile(', 'writetable(', 'imwrite('});
    assertComponentSourcesDoNotContain(testCase, root, fullfile(packageDir, '+view'), ...
        {'labkit.ui.app.create', 'uigridlayout(', 'uiaxes(', 'uialert(', ...
        'uigetfile(', 'uigetdir(', 'uiputfile(', 'writetable(', 'imwrite('});
    assertComponentSourcesDoNotContain(testCase, root, fullfile(packageDir, '+io'), ...
        {'labkit.ui.app.create', 'labkit.ui.spec', 'labkit.ui.view', ...
        'labkit.ui.tool', 'labkit.ui.diag', 'uialert(', 'uigridlayout(', ...
        'writetable(', 'imwrite('});
    assertComponentSourcesDoNotContain(testCase, root, fullfile(packageDir, '+export'), ...
        {'labkit.ui', 'uialert(', 'uigetfile(', 'uigetdir(', ...
        'uiputfile(', 'uigridlayout('});
    assertComponentSourcesDoNotContain(testCase, root, fullfile(packageDir, '+state'), ...
        {'labkit.ui', 'uialert(', 'uigetfile(', 'uigetdir(', ...
        'uiputfile(', 'writetable(', 'imwrite(', 'uigridlayout('});
end

function assertComponentSourcesDoNotContain(testCase, root, folder, forbiddenWords)
    if ~isfolder(folder)
        return;
    end

    files = dir(fullfile(folder, '*.m'));
    for k = 1:numel(files)
        filepath = fullfile(files(k).folder, files(k).name);
        assertSourceDoesNotContain(testCase, fileread(filepath), ...
            forbiddenWords, relativePath(root, filepath));
    end
end

function assertSourceDoesNotContain(testCase, source, forbiddenWords, label)
    matches = strings(1, 0);
    for k = 1:numel(forbiddenWords)
        word = forbiddenWords{k};
        if contains(source, word)
            matches(end+1) = string(word);
        end
    end

    testCase.verifyTrue(isempty(matches), ...
        [label ' contains code outside its app structure boundary: ' ...
        strjoin(cellstr(matches), ', ')]);
end

function source = readPackageSource(packageDir)
    files = dir(fullfile(packageDir, '**', '*.m'));
    parts = cell(1, numel(files));
    for k = 1:numel(files)
        parts{k} = fileread(fullfile(files(k).folder, files(k).name));
    end
    source = strjoin(parts, newline);
end

function assertAppOwnedPackageCapability(testCase, root, appDir, packageDir, family, packageName)
    testCase.verifyTrue(isfolder(packageDir), ...
        ['Missing app-owned package namespace: ' relativePath(root, packageDir)]);
    testCase.verifyFalse(isfolder(fullfile(packageDir, '+core')), ...
        ['App-owned package should not route through +core: ' relativePath(root, packageDir)]);
    testCase.verifyFalse(isfile(fullfile(packageDir, '+core', 'dispatch.m')), ...
        ['App-owned package should not keep +core/dispatch.m: ' relativePath(root, packageDir)]);

    packageFiles = dir(fullfile(packageDir, '**', '*.m'));
    testCase.verifyFalse(isempty(packageFiles), ...
        ['App-owned package should contain helper files: ' relativePath(root, packageDir)]);
    testCase.verifyTrue(hasNonUiPackageComponent(packageDir), ...
        ['App-owned package should expose directly testable non-UI behavior: ' ...
        relativePath(root, packageDir)]);
    testCase.verifyTrue(packageNamespaceHasDirectUnitTest(root, family, packageName), ...
        ['App-owned non-UI package functions should have direct unit tests: ' ...
        relativePath(root, packageDir)]);

    testCase.verifyFalse(isfile(fullfile(packageDir, '+ui', 'runApp.m')), ...
        ['App-owned package should not keep app lifecycle orchestration in +ui/runApp.m: ' ...
        relativePath(root, appDir)]);
end

function family = appFamilyFromRelativeDir(appRelDir)
    parts = split(string(strrep(appRelDir, filesep, '/')), '/');
    family = char(parts(2));
end

function tf = hasNonUiPackageComponent(packageDir)
    componentNames = {'+ops', '+view', '+export', '+io', '+state', '+appState', ...
        '+sourceFiles', '+analysisRun', '+resultFiles', '+cropGeometry', ...
        '+thermalFrames', '+debugArtifacts'};
    tf = false;
    for k = 1:numel(componentNames)
        componentRoot = fullfile(packageDir, componentNames{k});
        files = dir(fullfile(componentRoot, '*.m'));
        if isfolder(componentRoot) && any(~[files.isdir])
            tf = true;
            return;
        end
    end
end

function tf = packageNamespaceHasDirectUnitTest(root, family, packageName)
    testRoot = fullfile(root, 'tests', 'cases', 'unit', 'apps', family);
    if ~isfolder(testRoot)
        tf = false;
        return;
    end

    componentPattern = ['ops|view|export|io|state|appState|sourceFiles|' ...
        'analysisRun|resultFiles|cropGeometry|thermalFrames|debugArtifacts'];
    pattern = [packageName '\.(' componentPattern ')\.'];
    testFiles = collectTextFiles(testRoot);
    tf = false;
    for k = 1:numel(testFiles)
        if ~isempty(regexp(fileread(testFiles{k}), pattern, 'once'))
            tf = true;
            return;
        end
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

function rel = relativePath(root, filepath)
    rel = filepath;
    prefix = [root filesep];
    if startsWith(filepath, prefix)
        rel = filepath(numel(prefix)+1:end);
    end
    rel = strrep(rel, filesep, '/');
end

function filepath = repoPath(root, pathValue)
    parts = [{char(root)}; cellstr(split(string(pathValue), "/"))];
    filepath = fullfile(parts{:});
end
