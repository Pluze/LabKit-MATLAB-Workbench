classdef AppPackageStructureGuardrailTest < matlab.unittest.TestCase
    %APPPACKAGESTRUCTUREGUARDRAILTEST Enforce the final App SDK package shape.

    methods (Test, TestTags = {'Integration', 'Style'})
        function supportedAppsUseCanonicalAppPackageStructure(testCase)
            root = setupLabKitTestPath();
            apps = discoveredApps(root);
            testCase.assertFalse(isempty(apps), ...
                "App package guardrail should discover entrypoints.");

            for k = 1:size(apps, 1)
                assertCanonicalShape(testCase, root, ...
                    apps{k, 1}, apps{k, 2}, apps{k, 3});
            end
        end

        function definitionsCompileAsExplicitSdkContracts(testCase)
            setupLabKitTestPath();
            apps = discoveredApps(pwd);
            for k = 1:size(apps, 1)
                packageName = string(apps{k, 2});
                definition = feval(packageName + ".definition");
                testCase.verifyClass(definition, "labkit.app.Definition", ...
                    packageName + ...
                    ".definition must return labkit.app.Definition.");
            end
        end

        function appFoldersDoNotMixFileAndFolderForms(testCase)
            root = setupLabKitTestPath();
            apps = discoveredApps(root);
            for k = 1:size(apps, 1)
                appDir = fullfile(root, apps{k, 1});
                assertNoSameStemFileFolder(testCase, root, appDir);
                assertNoSameStemFileFolder(testCase, root, ...
                    fullfile(appDir, ['+' apps{k, 2}]));
            end
        end

        function appCodeDoesNotCallSiblingAppPackages(testCase)
            root = setupLabKitTestPath();
            apps = discoveredApps(root);
            packageNames = string(apps(:, 2));
            for k = 1:size(apps, 1)
                appDir = fullfile(root, apps{k, 1});
                owner = packageNames(k);
                assertNoSiblingAppCalls(testCase, root, appDir, owner, ...
                    packageNames(packageNames ~= owner));
            end
        end

        function sessionFactoriesDoNotSwallowRestoreFailures(testCase)
            root = setupLabKitTestPath();
            apps = discoveredApps(root);
            for k = 1:size(apps, 1)
                filepath = fullfile(root, apps{k, 1}, ...
                    ['+' apps{k, 2}], 'createSession.m');
                if ~isfile(filepath)
                    continue;
                end
                source = string(fileread(filepath));
                testCase.verifyEmpty(regexp(source, ...
                    '(?m)^\s*catch(?:\s+\w+)?\s*$', 'once'), ...
                    relativePath(root, filepath) + ...
                    " must let reconstruction failures reach Runtime.");
            end
        end

        function completeRuntimeStateStopsAtDeclaredAdapters(testCase)
            root = setupLabKitTestPath();
            apps = discoveredApps(root);
            for k = 1:size(apps, 1)
                assertRuntimeStateFunnel(testCase, root, ...
                    apps{k, 1}, apps{k, 2});
            end
        end
    end
end

function assertCanonicalShape(testCase, root, appRelDir, ...
        packageName, entrypointName)
appDir = fullfile(root, appRelDir);
packageDir = fullfile(appDir, ['+' packageName]);
workbenchDir = fullfile(packageDir, '+workbench');
entrypointFile = fullfile(appDir, entrypointName);
definitionFile = fullfile(packageDir, 'definition.m');
layoutFile = fullfile(workbenchDir, 'buildLayout.m');
label = string(relativePath(root, appDir));

testCase.verifyTrue(isfile(entrypointFile), ...
    "Missing App entrypoint: " + relativePath(root, entrypointFile));
testCase.verifyTrue(isfile(definitionFile), ...
    "Missing App definition: " + relativePath(root, definitionFile));
testCase.verifyTrue(isfile(layoutFile), ...
    "Missing canonical workbench assembly: " + ...
    relativePath(root, layoutFile));

testCase.verifyFalse(isfile(fullfile(packageDir, 'run.m')), ...
    label + " must not own package-root launch orchestration.");
testCase.verifyFalse(isfile(fullfile(packageDir, 'definitionActions.m')), ...
    label + " must bind semantic callbacks directly from layout.");
testCase.verifyFalse(isfile(fullfile(packageDir, 'stateHandlers.m')), ...
    label + " must not maintain a handler registry.");
for folder = ["+userInterface", "+actions", "+renderers", "+ops", ...
        "+io", "+ui", "+view", "+state", "+export", "+appLifecycle", ...
        "+appState", "+core"]
    testCase.verifyFalse(packageContainsMFile( ...
        fullfile(packageDir, char(folder))), ...
        label + " contains retired technical package " + folder + ".");
end

entrypointSource = string(fileread(entrypointFile));
definitionSource = string(fileread(definitionFile));
layoutSource = string(fileread(layoutFile));
testCase.verifyTrue(contains(entrypointSource, ...
    packageName + ".definition().launch("), ...
    label + " entrypoint must delegate directly to Definition.launch.");
testCase.verifyTrue(contains(definitionSource, ...
    "labkit.app.Definition("), ...
    label + " definition must use the explicit App SDK.");
testCase.verifyTrue(contains(definitionSource, ...
    packageName + ".workbench.buildLayout()"), ...
    label + " definition must name its workbench assembly.");
testCase.verifyTrue(contains(layoutSource, ...
    "labkit.app.layout.workbench("), ...
    relativePath(root, layoutFile) + ...
    " must return a semantic App SDK workbench.");

assertSourceDoesNotContain(testCase, layoutSource, ...
    concreteLayoutWords(), relativePath(root, layoutFile));
assertNoGenericHelperNames(testCase, root, packageDir);

for filename = ["requirements.m", "version.m", "startup.m"]
    testCase.verifyFalse(isfile(fullfile(packageDir, filename)), ...
        label + " must not own " + filename + ".");
end
projectSpec = fullfile(packageDir, 'projectSpec.m');
if isfile(projectSpec)
    testCase.verifyTrue(contains(definitionSource, ...
        packageName + ".projectSpec()"), ...
        label + " owns projectSpec.m but definition does not declare it.");
end
createSession = fullfile(packageDir, 'createSession.m');
if isfile(createSession)
    testCase.verifyTrue(contains(definitionSource, ...
        "@" + packageName + ".createSession"), ...
        label + " owns createSession.m but definition does not declare it.");
end
end

function apps = discoveredApps(root)
entries = dir(fullfile(root, 'apps', '**', 'labkit_*_app.m'));
[~, order] = sort(string(fullfile({entries.folder}, {entries.name})));
entries = entries(order);
apps = cell(numel(entries), 3);
for k = 1:numel(entries)
    appDir = entries(k).folder;
    packageDirs = dir(fullfile(appDir, '+*'));
    packageDirs = packageDirs([packageDirs.isdir]);
    packageNames = sort(extractAfter(string({packageDirs.name}), 1));
    packageName = "";
    if ~isempty(packageNames)
        packageName = packageNames(1);
    end
    apps{k, 1} = relativePath(root, appDir);
    apps{k, 2} = char(packageName);
    apps{k, 3} = entries(k).name;
end
end

function assertNoSiblingAppCalls(testCase, root, appDir, owner, siblings)
files = dir(fullfile(appDir, "**", "*.m"));
for k = 1:numel(files)
    filepath = fullfile(files(k).folder, files(k).name);
    source = string(fileread(filepath));
    code = regexprep(source, "(?m)^\s*%[^\n]*", "");
    for sibling = siblings.'
        pattern = "(?<![A-Za-z0-9_])" + sibling + ...
            "(?:\.[A-Za-z]\w*)+\s*\(";
        testCase.verifyEmpty(regexp(code, pattern, "once"), ...
            relativePath(root, filepath) + ...
            " must exchange a saved contract with " + sibling + ...
            ", not call it from " + owner + ".");
    end
end
end

function assertRuntimeStateFunnel(testCase, root, appRelDir, packageName)
appDir = fullfile(root, appRelDir);
packageDir = fullfile(appDir, ['+' packageName]);
files = dir(fullfile(packageDir, '**', '*.m'));
adapterFunctions = packageName + ".workbench.present";
layoutHandles = cell(numel(files), 1);

for k = 1:numel(files)
    filepath = fullfile(files(k).folder, files(k).name);
    source = string(fileread(filepath));
    if contains(source, "labkit.app.layout.") || ...
            files(k).name == "definition.m"
        handles = regexp(source, ...
            '@([A-Za-z]\w*(?:\.[A-Za-z]\w*)+)', 'tokens');
        if ~isempty(handles)
            layoutHandles{k} = string(cellfun(@(value) value{1}, handles, ...
                'UniformOutput', false));
        end
    end
end
adapterFunctions = unique([adapterFunctions, layoutHandles{:}]);

for k = 1:numel(files)
    filepath = fullfile(files(k).folder, files(k).name);
    source = string(fileread(filepath));
    if ~contains(source, ".project") && ~contains(source, ".session")
        continue;
    end
    declarations = regexp(source, ...
        '(?m)^\s*function[^\n]*\(\s*(?:applicationState|state)\b[^\n]*', ...
        'match');
    if isempty(declarations)
        continue;
    end
    qualified = qualifiedFunctionName(packageDir, packageName, filepath);
    testCase.verifyTrue(any(qualified == adapterFunctions), ...
        relativePath(root, filepath) + ...
        " accepts complete runtime state outside a declared adapter.");
    testCase.verifyNumElements(declarations, 1, ...
        relativePath(root, filepath) + ...
        " forwards complete runtime state into a local helper.");
    testCase.verifyTrue(contains(string(declarations{1}), ...
        "(applicationState"), ...
        relativePath(root, filepath) + ...
        " must name the SDK transaction envelope applicationState.");
end

featurePresenters = dir(fullfile(packageDir, '+*', 'present.m'));
for k = 1:numel(featurePresenters)
    filepath = fullfile(featurePresenters(k).folder, ...
        featurePresenters(k).name);
    if string(featurePresenters(k).folder) == ...
            string(fullfile(packageDir, '+workbench'))
        continue;
    end
    source = string(fileread(filepath));
    testCase.verifyEmpty(regexp(source, ...
        '(?m)^\s*function[^\n]*\(\s*(?:applicationState|state)\b', ...
        'once'), ...
        relativePath(root, filepath) + ...
        " must receive explicit display inputs, not runtime state.");
end
end

function name = qualifiedFunctionName(packageDir, packageName, filepath)
relative = erase(string(filepath), string(packageDir) + filesep);
parts = split(relative, filesep);
parts = erase(parts, "+");
parts(end) = erase(parts(end), ".m");
name = packageName + "." + strjoin(parts, ".");
end

function assertNoSameStemFileFolder(testCase, root, folder)
if ~isfolder(folder)
    return;
end
files = dir(fullfile(folder, '*.m'));
dirs = dir(folder);
dirs = dirs([dirs.isdir]);
dirs = dirs(~ismember({dirs.name}, {'.', '..'}));
conflicts = intersect(erase(string({files.name}), ".m"), ...
    erase(string({dirs.name}), "+"));
testCase.verifyTrue(isempty(conflicts), ...
    relativePath(root, folder) + ...
    " mixes file and folder forms for: " + strjoin(conflicts, ", "));
end

function words = concreteLayoutWords()
words = ["uifigure(", "uigridlayout(", "uibutton(", "uilabel(", ...
    "uidropdown(", "uispinner(", "uieditfield(", "uitable(", ...
    "uiaxes(", "uitextarea(", "Layout.Row", "Layout.Column", ...
    "uigetfile(", "uigetdir(", "uiputfile(", "uialert(", ...
    "writetable(", "imwrite(", "labkit.app.internal."];
end

function assertNoGenericHelperNames(testCase, root, packageDir)
forbidden = ["helpers.m", "utils.m", "common.m", "misc.m", ...
    "functions.m", "callbacks.m", "manager.m", "processor.m", ...
    "layout.m", "createUI.m", "createUi.m", "makeUI.m", "place.m"];
files = dir(fullfile(packageDir, '**', '*.m'));
bad = strings(1, 0);
for k = 1:numel(files)
    if any(string(files(k).name) == forbidden)
        bad(end + 1) = relativePath(root, ...
            fullfile(files(k).folder, files(k).name));
    end
end
testCase.verifyTrue(isempty(bad), ...
    "App files must name owned capabilities: " + strjoin(bad, ", "));
end

function assertSourceDoesNotContain(testCase, source, words, label)
matches = words(arrayfun(@(word) contains(source, word), words));
testCase.verifyTrue(isempty(matches), ...
    label + " contains code outside layout assembly: " + ...
    strjoin(matches, ", "));
end

function tf = packageContainsMFile(folder)
if ~isfolder(folder)
    tf = false;
    return;
end
files = dir(fullfile(folder, '**', '*.m'));
tf = any(~[files.isdir]);
end

function rel = relativePath(root, filepath)
rel = string(filepath);
prefix = string(root) + filesep;
if startsWith(rel, prefix)
    rel = extractAfter(rel, strlength(prefix));
end
rel = replace(rel, filesep, "/");
end
