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

            formerWrapperName = "run_" + "matlab_tests";

            oldWrapperDocs = [ ...
                string(fullfile(root, "README.md")), ...
                string(fullfile(root, "docs", "testing.md"))];
            for k = 1:numel(oldWrapperDocs)
                testCase.verifyFalse(contains(fileread(oldWrapperDocs(k)), ...
                    formerWrapperName), ...
                    "User-facing docs should not reference the former test wrapper: " + ...
                    relativePath(root, oldWrapperDocs(k)));
                testCase.verifyFalse(contains(fileread(oldWrapperDocs(k)), ...
                    "runLabKitTests"), ...
                    "User-facing docs should route test commands through buildtool: " + ...
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

        function focusedRunnerCanSkipHtmlReport(testCase)
            root = setupLabKitTestPath();
            artifactsRoot = tempname;
            cleanup = onCleanup(@() removeTempFolder(artifactsRoot));

            output = runLabKitTests( ...
                "Tests", "suppressionPatternMatchesExpectedAndNonExpectedLines", ...
                "HtmlReport", false, ...
                "RunName", "html_report_off_probe", ...
                "ArtifactsRoot", artifactsRoot, ...
                "OutputDetail", "None");

            testCase.verifyTrue(isfile(output.artifacts.junitXml), ...
                "Focused runner should still write JUnit when HTML is disabled.");
            testCase.verifyFalse(isfile(fullfile(output.artifacts.testHtml, "index.html")), ...
                "HtmlReport=false should skip the HTML report index.");
            testCase.verifyTrue(startsWith(string(output.artifacts.root), string(artifactsRoot)), ...
                "Focused runner should keep artifacts under the requested root.");
            clear cleanup
        end

        function validationPlanListsMultipleSelections(testCase)
            setupLabKitTestPath();

            output = listLabKitTestsQuietly( ...
                "Plan", "ui", ...
                "HtmlReport", false, ...
                "RunName", "ui_plan_probe");

            testCase.verifyEqual(output.plan, "ui", ...
                "Plan should report the selected named validation plan.");
            testCase.verifyEqual(numel(output.steps), 2, ...
                "The UI validation plan should run reusable UI and downstream app GUI checks.");
            testCase.verifyEqual([output.steps.IncludeGui], [true true], ...
                "The UI validation plan should include GUI structural coverage.");
            testCase.verifyGreaterThan(output.count, 0, ...
                "Plan=list-only mode should still discover tests.");
        end

        function affectedValidationMapperCoversSharedUiAndAppChanges(testCase)
            root = setupLabKitTestPath();

            steps = labkitValidationPlanForChangedPaths(root, [ ...
                "+labkit/+ui/+app/runBusy.m", ...
                "apps/image_measurement/batch_crop/run.m"]);
            signatures = validationStepSignatures(steps);

            testCase.verifyTrue(any(signatures == "labkit/ui|true"), ...
                "Shared UI changes should run reusable UI GUI checks.");
            testCase.verifyTrue(any(signatures == "gui/apps|true"), ...
                "Shared UI changes should run downstream app GUI checks.");
            testCase.verifyTrue(any(signatures == "apps/image_measurement|false"), ...
                "Changed app source should run its app-owned non-GUI tests.");
            testCase.verifyFalse(any(signatures == ...
                "gui/apps/image_measurement/batch_crop|true"), ...
                "Broad downstream app GUI coverage should replace narrower app GUI targets.");
        end

        function changedValidationMapperTargetsSingleAppGui(testCase)
            root = setupLabKitTestPath();

            steps = labkitValidationPlanForChangedPaths(root, ...
                "apps/image_measurement/batch_crop/run.m");
            signatures = validationStepSignatures(steps);

            testCase.verifyTrue(any(signatures == ...
                "gui/apps/image_measurement/batch_crop|true"), ...
                "App-only changes should run the matching app GUI test folder.");
        end

        function affectedValidationMapperFallsBackConservatively(testCase)
            root = setupLabKitTestPath();

            steps = labkitValidationPlanForChangedPaths(root, ...
                "unmapped/tooling/file.txt");

            testCase.verifyEqual(numel(steps), 1, ...
                "Unknown changed paths should produce one conservative fallback step.");
            testCase.verifyEmpty(steps.Suites, ...
                "Unknown changed paths should fall back to the full non-GUI selection.");
            testCase.verifyFalse(steps.IncludeGui, ...
                "Unknown changed paths should keep the fallback non-GUI by default.");
        end

        function changedValidationPlanAvoidsGuiForDocsAndRunner(testCase)
            root = setupLabKitTestPath();

            steps = labkitValidationPlanForChangedPaths(root, [ ...
                "docs/apps.md", ...
                "tests/runner/labkitArtifactPaths.m"]);
            signatures = validationStepSignatures(steps);

            testCase.verifyEqual(signatures, "|false", ...
                "Docs plus runner changes should compress to one headless step.");
            testCase.verifyFalse(any([steps.IncludeGui]), ...
                "Docs and runner changes should not trigger GUI validation.");
        end

        function changedValidationPlanRoutesScopedAgentDocsToProject(testCase)
            root = setupLabKitTestPath();

            steps = labkitValidationPlanForChangedPaths(root, [
                "apps/AGENTS.md"
                "+labkit/AGENTS.md"
                "tests/AGENTS.md"]);
            signatures = validationStepSignatures(steps);

            testCase.verifyEqual(signatures, "project|false", ...
                "Scoped AGENTS changes should run project guardrails, not " + ...
                "invalid app or package suite names.");
        end

        function changedValidationPlanCompressesCoveredGuiTargets(testCase)
            root = setupLabKitTestPath();

            steps = labkitValidationPlanForChangedPaths(root, [ ...
                "tests/cases/gui/apps/AppLaunchGuiTest.m", ...
                "tests/cases/gui/apps/image_measurement/batch_crop/GuiLayoutBatchCropTest.m"]);
            signatures = validationStepSignatures(steps);

            testCase.verifyEqual(signatures, "gui|true", ...
                "The broad GUI step should cover narrower app GUI targets.");
        end

        function buildTaskCatalogStaysCompactAndDiscoveryDriven(testCase)
            root = setupLabKitTestPath();
            catalog = extractBuildfileCatalog(root);

            expectedTasks = ["changed", "headless", "gui", "coverage", ...
                "listTasks"];
            testCase.verifyEqual(catalog.Name(:).', expectedTasks, ...
                "Build task catalog should expose a compact intent-based task set.");

            retiredPrefixes = ["test", "checkStyle", "core", "project", ...
                "matlabProject", "packageDryRun", "testLabkitDta", ...
                "testLabkitBiosignal", "testLabkitUi", ...
                "testAppsElectrochem", "testAppsDic", ...
                "testAppsImageMeasurement", "testAppsWearable", ...
                "testAppsTemplates", "testAppsSmoke"];
            for k = 1:numel(retiredPrefixes)
                testCase.verifyFalse(any(startsWith(catalog.Name, retiredPrefixes(k))), ...
                    "Build tasks should stay intent-based; use changed for " + ...
                    "granular local routing instead of " + retiredPrefixes(k) + "* tasks.");
            end
        end

        function userFacingDocsAvoidRetiredValidationVocabulary(testCase)
            root = setupLabKitTestPath();
            docFiles = [
                fullfile(root, "README.md")
                fullfile(root, "docs", "apps.md")
                fullfile(root, "docs", "testing.md")];
            retiredPhrases = [
                "changed-file, core, or GUI tasks"
                "project validation tasks"
                "buildtool core"
                "buildtool project"
                "buildtool testProject"
                "buildtool testGui"
                "buildtool testApps"
                "scripts/matlab_batch.sh"];

            for f = 1:numel(docFiles)
                content = string(fileread(docFiles(f)));
                for p = 1:numel(retiredPhrases)
                    testCase.verifyFalse(contains(content, retiredPhrases(p)), ...
                        "User-facing validation docs should not mention retired task vocabulary: " + ...
                        relativePath(root, docFiles(f)) + " contains " + retiredPhrases(p));
                end
            end
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
    args = appendStringListArgument(args, line, "Plan");
    args = appendStringListArgument(args, line, "Tags");
    args = appendLogicalArgument(args, line, "IncludeGui");
    args = appendLogicalArgument(args, line, "IncludeCoverage");
    args = appendLogicalArgument(args, line, "HtmlReport");
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
    evalc(['output = runLabKitTests(varargin{:}, "ListOnly", true, ' ...
        '"FailIfNoTests", false);']);
end

function signatures = validationStepSignatures(steps)
    signatures = strings(1, numel(steps));
    for k = 1:numel(steps)
        signatures(k) = strjoin(steps(k).Suites, ",") + "|" + ...
            string(steps(k).IncludeGui);
    end
end

function removeTempFolder(folder)
    if exist(folder, "dir") == 7
        rmdir(folder, "s");
    end
end
