classdef BuildTaskFrameworkGuardrailTest < matlab.unittest.TestCase
    %BUILDTASKFRAMEWORKGUARDRAILTEST Guardrails for build task routing.

    methods (Test, TestTags = {'Integration', 'Style'})
        function buildTaskCatalogMatchesTaskFunctions(testCase)
            root = setupLabKitTestPath();
            catalog = extractBuildfileCatalog(root);
            taskFunctions = extractTaskFunctionNames(root);

            testCase.verifyEqual(sort(catalog.Name(:).'), sort(taskFunctions(:).'), ...
                'Every public build task function should have one catalog entry.');
            testCase.verifyEqual(numel(unique(catalog.Name)), numel(catalog.Name), ...
                'Build task catalog entries should be unique.');
            testCase.verifyTrue(all(strlength(catalog.Description) > 0), ...
                'Build task catalog entries should carry non-empty descriptions.');
        end

        function documentedBuildTasksStayInCatalog(testCase)
            root = setupLabKitTestPath();
            catalog = extractBuildfileCatalog(root);
            catalogNames = catalog.Name;

            testingDoc = fullfile(root, "docs", "testing.md");
            matrixTasks = extractPrimaryTestingCommandMatrix(fileread(testingDoc));
            testCase.verifyFalse(isempty(matrixTasks), ...
                "docs/testing.md task matrix should be parseable.");
            testCase.verifyEqual(matrixTasks(:), catalogNames(:), ...
                "docs/testing.md task matrix should match buildfile catalog order.");

            docFiles = [ ...
                fullfile(root, "README.md"), ...
                testingDoc];
            for k = 1:numel(docFiles)
                tasks = extractBuildtoolTasks(fileread(docFiles(k)));
                verifyTaskSubset(testCase, tasks, catalogNames, ...
                    "Documented buildtool tasks in " + relativePath(root, docFiles(k)));
            end

            batchLocator = string(fileread(fullfile(root, "scripts", ...
                "matlab_batch.sh")));
            formerWrapperName = "run_" + "matlab_tests";
            testCase.verifyFalse(contains(batchLocator, formerWrapperName), ...
                'MATLAB locator should not reintroduce the former test wrapper.');
            testCase.verifyFalse(contains(batchLocator, "TASK"), ...
                'MATLAB locator should not parse or own build task names.');

            oldWrapperDocs = [ ...
                string(fullfile(root, "README.md")), ...
                string(fullfile(root, "docs", "testing.md"))];
            for k = 1:numel(oldWrapperDocs)
                testCase.verifyFalse(contains(fileread(oldWrapperDocs(k)), ...
                    formerWrapperName), ...
                    "User-facing docs should not reference the former test wrapper: " + ...
                    relativePath(root, oldWrapperDocs(k)));
            end
        end

        function focusedBuildTasksMatchAtLeastOneTest(testCase)
            root = setupLabKitTestPath();
            taskSpecs = focusedTaskSpecs(root);
            testCase.assertFalse(isempty(taskSpecs), ...
                "Runnable build task specs should be discovered from buildfile.m.");
            for k = 1:numel(taskSpecs)
                spec = taskSpecs(k);
                output = listLabKitTestsQuietly(spec.Args{:}, ...
                    "RunName", spec.Name + "_list");
                testCase.verifyGreaterThan(output.count, 0, ...
                    "Focused build task should match tests: " + spec.Name);
            end
        end

        function defaultRunnerSelectionExcludesGuiTests(testCase)
            setupLabKitTestPath();
            output = listLabKitTestsQuietly( ...
                "IncludeGui", false, ...
                "RunName", "default_list");

            testCase.verifyGreaterThan(output.count, 0, ...
                'Default non-GUI runner selection should not be empty.');
            testCase.verifyFalse(any(contains(output.tests.Tags, "GUI")), ...
                'Default non-GUI runner selection must not include GUI tests.');
        end

        function buildTaskCatalogStaysCompactAndDiscoveryDriven(testCase)
            root = setupLabKitTestPath();
            catalog = extractBuildfileCatalog(root);

            granularPrefixes = ["testLabkitDta", "testLabkitBiosignal", ...
                "testLabkitUi", "testAppsElectrochem", "testAppsDic", ...
                "testAppsImageMeasurement", "testAppsWearable", ...
                "testAppsTemplates", "testAppsSmoke"];
            for k = 1:numel(granularPrefixes)
                testCase.verifyFalse(any(startsWith(catalog.Name, granularPrefixes(k))), ...
                    "Build tasks should stay compact; use runLabKitTests Suites for " + ...
                    "granular routing instead of " + granularPrefixes(k) + "* tasks.");
            end

            expectedDiscoveryTasks = ["testLabkit", "testLabkitGui", ...
                "testApps", "testAppsGui"];
            missing = setdiff(expectedDiscoveryTasks, catalog.Name);
            testCase.verifyTrue(isempty(missing), ...
                "Build catalog should expose broad discovery-driven tasks: " + ...
                strjoin(missing, ", "));
        end

        function testFilesUseKnownTags(testCase)
            root = setupLabKitTestPath();
            allowedTags = ["Unit", "Integration", "GUI", "Structural", ...
                "Gesture", "Style", "Smoke"];
            files = collectTestFiles(fullfile(root, "tests"));
            testCase.assertFalse(isempty(files), ...
                'Test tag guardrail should scan test files.');

            for k = 1:numel(files)
                content = fileread(files(k));
                tagGroups = regexp(content, 'TestTags\s*=\s*\{([^}]*)\}', ...
                    'tokens');
                rel = relativePath(root, files(k));
                testCase.verifyFalse(isempty(tagGroups), ...
                    "Test file is missing TestTags: " + rel);
                for g = 1:numel(tagGroups)
                    tags = extractQuotedTags(tagGroups{g}{1});
                    testCase.verifyFalse(isempty(tags), ...
                        "TestTags block is empty: " + rel);
                    unknown = setdiff(tags, allowedTags);
                    testCase.verifyTrue(isempty(unknown), ...
                        "Unknown TestTags in " + rel + ": " + strjoin(unknown, ", "));
                end
            end
        end

    end
end

function catalog = extractBuildfileCatalog(root)
    content = fileread(fullfile(root, "buildfile.m"));
    tokens = regexp(content, 'taskSpec\("([^"]+)",\s*"([^"]+)"', 'tokens');
    names = strings(1, numel(tokens));
    descriptions = strings(1, numel(tokens));
    for k = 1:numel(tokens)
        names(k) = string(tokens{k}{1});
        descriptions(k) = string(tokens{k}{2});
    end
    catalog = table(names.', descriptions.', ...
        'VariableNames', {'Name', 'Description'});
end

function names = extractTaskFunctionNames(root)
    content = fileread(fullfile(root, "buildfile.m"));
    tokens = regexp(content, ...
        '(?m)^function\s+([A-Za-z][A-Za-z0-9_]*)Task\s*\(~\)', 'tokens');
    names = strings(1, numel(tokens));
    for k = 1:numel(tokens)
        names(k) = string(tokens{k}{1});
    end
end

function tasks = extractBuildtoolTasks(content)
    tokens = regexp(char(content), ...
        'buildtool[ \t]+([A-Za-z][A-Za-z0-9_]*(?:[ \t]+[A-Za-z][A-Za-z0-9_]*)*)', ...
        'tokens');
    tasks = strings(1, 0);
    for k = 1:numel(tokens)
        tasks = [tasks, split(string(tokens{k}{1})).'];
    end
    tasks = unique(tasks(strlength(tasks) > 0), 'stable');
end

function tasks = extractPrimaryTestingCommandMatrix(content)
    content = char(content);
    sectionStart = strfind(content, 'Use MATLAB build tasks for the stable official entry points:');
    if isempty(sectionStart)
        tasks = strings(1, 0);
        return;
    end

    content = content(sectionStart(1):end);
    blocks = regexp(content, '```bash\s*(.*?)```', 'tokens');
    if isempty(blocks)
        tasks = strings(1, 0);
        return;
    end

    tokens = regexp(blocks{1}{1}, ...
        '(?m)^buildtool[ \t]+([A-Za-z][A-Za-z0-9_]*)[ \t]*$', 'tokens');
    tasks = strings(1, numel(tokens));
    for k = 1:numel(tokens)
        tasks(k) = string(tokens{k}{1});
    end
end

function verifyTaskSubset(testCase, tasks, catalogNames, label)
    missing = setdiff(tasks, catalogNames);
    testCase.verifyTrue(isempty(missing), ...
        label + " not in buildfile catalog: " + strjoin(missing, ", "));
end

function taskSpecs = focusedTaskSpecs(root)
    specs = parseRunnableTaskSpecs(root);
    taskSpecs = specs([specs.Required]);
end

function specs = parseRunnableTaskSpecs(root)
    content = fileread(fullfile(root, "buildfile.m"));
    lines = string(splitlines(content));
    lines = lines(contains(lines, "taskSpec("));
    specs = struct("Name", {}, "Args", {}, "Required", {});
    for k = 1:numel(lines)
        line = string(lines{k});
        nameTokens = regexp(line, 'taskSpec\("([^"]+)"', 'tokens', 'once');
        if isempty(nameTokens) || contains(line, '"RunTests", false')
            continue;
        end

        required = ~contains(line, '"Required", false');
        args = taskSpecArguments(line);
        specs(end+1) = struct( ...
            "Name", string(nameTokens{1}), ...
            "Args", {args}, ...
            "Required", required);
    end
end

function args = taskSpecArguments(line)
    args = {};
    args = appendStringListArgument(args, line, "Suites");
    args = appendStringListArgument(args, line, "Tags");
    args = appendLogicalArgument(args, line, "IncludeGui");
    args = appendLogicalArgument(args, line, "IncludeCoverage");
end

function args = appendStringListArgument(args, line, name)
    values = extractNameValueStrings(line, name);
    if isempty(values)
        return;
    end
    args = [args, {char(name), values}];
end

function values = extractNameValueStrings(line, name)
    pattern = '"' + name + '"\s*,\s*(\[[^\]]+\]|"[^"]*")';
    token = regexp(line, pattern, 'tokens', 'once');
    if isempty(token)
        values = strings(1, 0);
        return;
    end

    valueTokens = regexp(token{1}, '"([^"]+)"', 'tokens');
    values = strings(1, numel(valueTokens));
    for k = 1:numel(valueTokens)
        values(k) = string(valueTokens{k}{1});
    end
end

function args = appendLogicalArgument(args, line, name)
    value = extractNameValueLogical(line, name);
    if isempty(value)
        return;
    end
    args = [args, {char(name), value}];
end

function value = extractNameValueLogical(line, name)
    pattern = '"' + name + '"\s*,\s*(true|false)';
    token = regexp(line, pattern, 'tokens', 'once');
    if isempty(token)
        value = [];
        return;
    end

    value = strcmp(token{1}, "true");
end

function files = collectTestFiles(root)
    files = strings(1, 0);
    entries = dir(root);
    [~, order] = sort({entries.name});
    entries = entries(order);
    for k = 1:numel(entries)
        entry = entries(k);
        if entry.isdir
            if strcmp(entry.name, ".") || strcmp(entry.name, "..")
                continue;
            end
            files = [files, collectTestFiles(fullfile(entry.folder, entry.name))];
        elseif endsWith(entry.name, "Test.m")
            files(end+1) = string(fullfile(entry.folder, entry.name));
        end
    end
end

function tags = extractQuotedTags(content)
    tokens = regexp(content, '''([^'']+)''', 'tokens');
    tags = strings(1, numel(tokens));
    for k = 1:numel(tokens)
        tags(k) = string(tokens{k}{1});
    end
end

function rel = relativePath(root, filepath)
    rel = replace(string(filepath), "\", "/");
    root = replace(string(root), "\", "/");
    if startsWith(rel, root + "/")
        rel = extractAfter(rel, strlength(root) + 1);
    end
end

function output = listLabKitTestsQuietly(varargin)
    evalc('output = runLabKitTests(varargin{:}, "ListOnly", true);');
end
