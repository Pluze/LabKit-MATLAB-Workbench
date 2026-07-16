classdef AppPackageStructureGuardrailTest < matlab.unittest.TestCase
    %APPPACKAGESTRUCTUREGUARDRAILTEST Guardrails for app package layout.

    methods (Test, TestTags = {'Integration', 'Style'})
        function supportedAppsUseCanonicalAppPackageStructure(testCase)
            root = setupLabKitTestPath();
            layouts = discoveredAppLayouts(root);
            testCase.assertFalse(isempty(layouts), ...
                'App package structure guardrail should discover app entrypoints.');

            for k = 1:size(layouts, 1)
                assertCanonicalAppPackageStructure(testCase, root, ...
                    layouts{k, 1}, layouts{k, 2}, layouts{k, 3});
            end
        end

        function appFoldersDoNotMixFileAndFolderForms(testCase)
            root = setupLabKitTestPath();
            layouts = discoveredAppLayouts(root);
            for k = 1:size(layouts, 1)
                appDir = fullfile(root, layouts{k, 1});
                assertNoSameStemFileFolder(testCase, root, appDir);
                packageName = layouts{k, 2};
                if strlength(string(packageName)) > 0
                    assertNoSameStemFileFolder(testCase, root, ...
                        fullfile(appDir, ['+' packageName]));
                end
            end
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

function layouts = discoveredAppLayouts(root)
    entries = dir(fullfile(root, 'apps', '**', 'labkit_*_app.m'));
    [~, order] = sort(string(fullfile({entries.folder}, {entries.name})));
    entries = entries(order);
    layouts = cell(numel(entries), 3);
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
        layouts{k, 1} = relativePath(root, appDir);
        layouts{k, 2} = packageName;
        layouts{k, 3} = entries(k).name;
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
    buildLayoutFile = fullfile(userInterfaceDir, 'buildWorkbenchLayout.m');
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

    testCase.verifyTrue(isfile(buildLayoutFile), ...
        ['Apps must keep the ordinary data-only layout at ' ...
        relativePath(root, buildLayoutFile)]);
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
    usesBuildLayoutCall = contains(orchestrationSource, ...
        [packageName '.userInterface.buildWorkbenchLayout(']) || ...
        contains(orchestrationSource, ...
        ['@' packageName '.userInterface.buildWorkbenchLayout']);
    testCase.verifyTrue(usesBuildLayoutCall, ...
        [appLabel ' should call its canonical UI layout builder.']);
    usesLaunch = contains(orchestrationSource, 'labkit.ui.runtime.launch(') && ...
        contains(orchestrationSource, ['@' packageName '.definition']);
    testCase.verifyTrue(usesLaunch, ...
        [appLabel ' entrypoints should use the standard LabKit launch facade.']);

    buildLayoutSource = fileread(buildLayoutFile);
    testCase.verifyTrue(contains(buildLayoutSource, 'labkit.ui.layout.workbench'), ...
        [relativePath(root, buildLayoutFile) ' should return a semantic LabKit app layout.']);
    assertSourceDoesNotContain(testCase, buildLayoutSource, ...
        buildLayoutForbiddenWords(), relativePath(root, buildLayoutFile));
    assertNoAppOwnedLayoutProps(testCase, buildLayoutSource, ...
        relativePath(root, buildLayoutFile));
    assertNoEmptyUiSections(testCase, buildLayoutSource, ...
        relativePath(root, buildLayoutFile));

    assertNoGenericHelperNames(testCase, root, packageDir);
    family = appFamilyFromRelativeDir(appRelDir);
    assertAppOwnedPackageCapability(testCase, root, appDir, packageDir, ...
        family, packageName);
end

function assertWorkflowFirstPackageShape(testCase, root, packageDir)
    requiredFiles = [
        string(fullfile(packageDir, 'definitionActions.m'))
        string(fullfile(packageDir, '+appLifecycle', 'createProject.m'))
        string(fullfile(packageDir, '+appLifecycle', 'createSession.m'))
        string(fullfile(packageDir, '+appLifecycle', 'validateProject.m'))
        string(fullfile(packageDir, '+userInterface', 'buildWorkbenchLayout.m'))
        string(fullfile(packageDir, '+userInterface', 'presentWorkbench.m'))];
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

function words = buildLayoutForbiddenWords()
    words = {'uifigure(', 'uigridlayout(', 'uibutton(', 'uilabel(', ...
        'uidropdown(', 'uispinner(', 'uieditfield(', 'uitable(', ...
        'uiaxes(', 'uitextarea(', 'labkit.ui.runtime.create', ...
        'Layout.Row', 'Layout.Column', 'uigetfile(', 'uigetdir(', ...
        'uiputfile(', 'uialert(', 'writetable(', 'imwrite(', 'S.'};
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
        'labkit\.ui\.layout\.section[\s\S]*?\{\s*\}\s*\)', 'match');
    testCase.verifyTrue(isempty(matches), ...
        [label ' declares an empty UI section. Sections should contain ' ...
        'real controls or a semantic toolPanel host; do not leave titled ' ...
        'empty placeholders in app layouts.']);
end

function assertNoGenericHelperNames(testCase, root, packageDir)
    forbidden = {'helpers.m', 'utils.m', 'common.m', 'misc.m', ...
        'functions.m', 'callbacks.m', 'manager.m', 'processor.m', ...
        'layout.m', 'createUI.m', 'createUi.m', 'makeUI.m', 'place.m'};
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
    packageDirs = nonUiPackageDirectories(packageDir);
    tf = any(arrayfun(@(entry) packageContainsMFile( ...
        fullfile(entry.folder, entry.name)), packageDirs));
end

function tf = packageNamespaceHasDirectUnitTest(root, family, packageName)
    testRoot = fullfile(root, 'tests', 'cases', 'unit', 'apps', family);
    if ~isfolder(testRoot)
        tf = false;
        return;
    end

    pattern = [regexptranslate('escape', packageName) ...
        '\.(?!appLifecycle\.|userInterface\.)[A-Za-z]\w*\.'];
    testFiles = collectTextFiles(testRoot);
    tf = false;
    for k = 1:numel(testFiles)
        if ~isempty(regexp(fileread(testFiles{k}), pattern, 'once'))
            tf = true;
            return;
        end
    end
end

function entries = nonUiPackageDirectories(packageDir)
    entries = dir(fullfile(packageDir, '+*'));
    entries = entries([entries.isdir]);
    excluded = {'+appLifecycle', '+userInterface'};
    entries = entries(~ismember({entries.name}, excluded));
end

function tf = packageContainsMFile(folder)
    files = dir(fullfile(folder, '**', '*.m'));
    tf = any(~[files.isdir]);
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
