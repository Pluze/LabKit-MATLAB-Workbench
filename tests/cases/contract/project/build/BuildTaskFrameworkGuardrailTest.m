classdef BuildTaskFrameworkGuardrailTest < matlab.unittest.TestCase
    %BUILDTASKFRAMEWORKGUARDRAILTEST Guardrails for build task routing.

    methods (Test, TestTags = {'Integration', 'Style'})
        function buildTaskCatalogMatchesTaskFunctions(testCase)
            root = setupLabKitTestPath();
            catalog = labkitBuildTaskCatalog();
            taskFunctions = extractTaskFunctionNames(root);

            testCase.verifyEqual(sort([catalog.Name]), sort(taskFunctions(:).'), ...
                'Every public build task function should have one catalog entry.');
            testCase.verifyEqual(numel(unique([catalog.Name])), numel(catalog), ...
                'Build task catalog entries should be unique.');
            testCase.verifyTrue(all(strlength([catalog.Description]) > 0), ...
                'Build task catalog entries should carry non-empty descriptions.');
        end

        function documentedBuildTasksStayInCatalog(testCase)
            root = setupLabKitTestPath();
            catalog = labkitBuildTaskCatalog();
            catalogNames = [catalog([catalog.Visibility] == "public").Name];

            testingDoc = fullfile(root, "docs", "development", "testing.md");
            matrixTasks = extractPrimaryTestingCommandMatrix(fileread(testingDoc));
            testCase.verifyFalse(isempty(matrixTasks), ...
                "docs/development/maintain-and-release/testing.md task matrix should be parseable.");
            testCase.verifyEqual(matrixTasks(:), catalogNames(:), ...
                "docs/development/maintain-and-release/testing.md task matrix should match buildfile catalog order.");

            docFiles = [ ...
                fullfile(root, "README.md"), ...
                testingDoc];
            for k = 1:numel(docFiles)
                tasks = extractBuildtoolTasks(fileread(docFiles(k)));
                verifyTaskSubset(testCase, tasks, catalogNames, ...
                    "Documented buildtool tasks in " + relativePath(root, docFiles(k)));
            end

        end

        function runnableBuildTaskSpecsMapToKnownTestScopes(testCase)
            root = setupLabKitTestPath();
            catalog = labkitBuildTaskCatalog();
            taskSpecs = catalog([catalog.RunTests] & [catalog.Required]);
            testCase.assertFalse(isempty(taskSpecs), ...
                "Runnable build task specs should be discovered from buildfile.m.");
            for k = 1:numel(taskSpecs)
                spec = taskSpecs(k);
                testCase.verifyTrue(taskSpecMapsToKnownTests(root, spec), ...
                    "Runnable build task spec should map to known tests: " + spec.Name);
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

        function runnerRejectsFilePathsAsSuiteSelectors(testCase)
            setupLabKitTestPath();
            testCase.verifyError(@() runLabKitTests( ...
                "Suites", "tests/cases/unit/project/PlatformSkeletonTest.m", ...
                "ListOnly", true), ...
                "LabKit:Tests:SuiteSelectorIsFile");
        end

        function runnerFilesSelectsOnlyTheRequestedTestFile(testCase)
            root = setupLabKitTestPath();
            output = listLabKitTestsQuietly( ...
                "Files", fullfile(root, "tests", "cases", "unit", ...
                "project", "PlatformSkeletonTest.m"), ...
                "Tests", "artifactPathsUseRunnerLayout", ...
                "RunName", "explicit_file_probe");
            testCase.verifyEqual(output.count, 1);
            testCase.verifyTrue(contains(output.tests.Name, ...
                "PlatformSkeletonTest/artifactPathsUseRunnerLayout"));
        end

        function qualifiedMethodSelectorIsDiscoveredBeforeNameFiltering(testCase)
            setupLabKitTestPath();
            output = listLabKitTestsQuietly( ...
                "Tests", ...
                "PlatformSkeletonTest/artifactPathsUseRunnerLayout", ...
                "RunName", "qualified_method_selector_probe");
            testCase.verifyEqual(output.count, 1);
            testCase.verifyEqual(output.tests.Name, ...
                "PlatformSkeletonTest/artifactPathsUseRunnerLayout");
        end

        function kindPrefixedSuiteDiscoversFocusedMethodSelector(testCase)
            setupLabKitTestPath();
            output = listLabKitTestsQuietly( ...
                "Suites", "contract/apps", ...
                "Tests", ...
                "publicAppsLoadContractsAndDebugSamplesOnOwningPath", ...
                "RunName", "kind_prefixed_selector_probe");
            testCase.verifyEqual(output.count, 1);
            testCase.verifyEqual(output.tests.Name, ...
                "AppIsolatedPathContractTest/" + ...
                "publicAppsLoadContractsAndDebugSamplesOnOwningPath");
        end

        function runnerFilesRequiresGuiModeForGuiFiles(testCase)
            root = setupLabKitTestPath();
            guiFile = fullfile(root, "tests", "cases", "gui", ...
                "labkit_framework", "ui", "GuiStartupLifecycleTest.m");
            testCase.verifyError(@() runLabKitTests( ...
                "Files", guiFile, "ListOnly", true), ...
                "LabKit:Tests:GuiFileRequiresIncludeGui");
        end

        function runnerRejectsNonfiniteLogicalOptions(testCase)
            root = setupLabKitTestPath();
            testCase.verifyError(@() labkitParseRunnerOptions(root, ...
                "IncludeGui", NaN), ...
                "MATLAB:InputParser:ArgumentFailedValidation");
        end

        function suiteTargetNormalizationRemovesOnlyLeadingPrefixes(testCase)
            setupLabKitTestPath();
            actual = labkitNormalizeSuiteTargets([ ...
                "tests/cases/unit/project/build/", ...
                "archive/tests/cases/unit/project/build"]);
            testCase.verifyEqual(actual, [ ...
                "project/build", ...
                "archive/tests/cases/unit/project/build"]);
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
            testCase.verifyTrue(isfile(output.artifacts.testProgress), ...
                "Focused runner should write machine-readable test progress.");
            testCase.verifyTrue(isfile(output.artifacts.activeTest), ...
                "Focused runner should preserve the last active-test state.");
            progressText = string(fileread(output.artifacts.testProgress));
            testCase.verifyTrue(contains(progressText, '"event":"test_start"') && ...
                contains(progressText, '"event":"test_done"'), ...
                "Progress artifacts should identify test start and completion events.");
            testCase.verifyFalse(isfile(fullfile(output.artifacts.testHtml, "index.html")), ...
                "HtmlReport=false should skip the HTML report index.");
            testCase.verifyTrue(startsWith(string(output.artifacts.root), string(artifactsRoot)), ...
                "Focused runner should keep artifacts under the requested root.");
            clear cleanup
        end

        function changedValidationPlanQuotesParentGitRefs(testCase)
            root = setupLabKitTestPath();

            steps = labkitValidationPlanForChangedPaths(root, [
                "tests/runLabKitTests.m"
                "tests/cases/contract/project/build/BuildTaskFrameworkGuardrailTest.m"]);
            signatures = validationStepSignatures(steps);

            testCase.verifyEqual(signatures, "project/build|false", ...
                "Runner changes should route to runner/build contracts.");

            runnerSource = string(fileread(fullfile(root, "tests", "runLabKitTests.m")));
            required = [
                contains(runnerSource, ...
                    "diff --name-only --diff-filter=ACMRTUXB "" + shellDoubleQuote(ref)")
                contains(runnerSource, ...
                    "rev-parse --verify --quiet "" + shellDoubleQuote(ref)")
            ];
            for k = 1:numel(required)
                testCase.verifyTrue(required(k), ...
                    "Changed validation should quote git refs before system shell calls.");
            end
        end

        function affectedValidationMapperCoversSharedUiAndAppChanges(testCase)
            root = setupLabKitTestPath();

            steps = labkitValidationPlanForChangedPaths(root, [ ...
                "+labkit/+ui/+runtime/private/runAppBusyCallback.m", ...
                "apps/image_measurement/batch_crop/+batch_crop/definition.m"]);
            signatures = validationStepSignatures(steps);

            testCase.verifyTrue(any(signatures == "labkit_framework/ui|true"), ...
                "Shared UI changes should run reusable UI GUI checks.");
            testCase.verifyTrue(any(signatures == "gui/apps|true"), ...
                "Shared UI changes should run downstream app GUI checks.");
            testCase.verifyTrue(any(signatures == "apps/image_measurement|false"), ...
                "Changed app source should run its app-owned non-GUI tests.");
            testCase.verifyFalse(any(signatures == ...
                "gui/apps/image_measurement/batch_crop|true"), ...
                "Broad downstream app GUI coverage should replace narrower app GUI targets.");
        end

        function affectedValidationMapperCoversImageFacadeChanges(testCase)
            root = setupLabKitTestPath();

            steps = labkitValidationPlanForChangedPaths(root, ...
                "+labkit/+image/readFiles.m");
            signatures = validationStepSignatures(steps);

            testCase.verifyTrue(any(signatures == "labkit_framework/image|false"), ...
                "Image facade changes should run reusable image facade tests.");
            testCase.verifyTrue(any(signatures == "apps/image_measurement|false"), ...
                "Image facade changes should run downstream image app unit tests.");
            testCase.verifyTrue(any(signatures == "gui/apps/image_measurement|true"), ...
                "Image facade changes should run downstream image app GUI checks.");
        end

        function changedValidationMapperTargetsSingleAppGui(testCase)
            root = setupLabKitTestPath();

            steps = labkitValidationPlanForChangedPaths(root, ...
                "apps/image_measurement/batch_crop/+batch_crop/definition.m");
            signatures = validationStepSignatures(steps);

            testCase.verifyTrue(any(signatures == ...
                "gui/apps/image_measurement/batch_crop|true"), ...
                "App-only changes should run the matching app GUI test folder.");
        end

        function changedValidationMapperTargetsPackagedAppGui(testCase)
            root = setupLabKitTestPath();

            steps = labkitValidationPlanForChangedPaths(root, ...
                "apps/image_measurement/batch_crop/+batch_crop/definitionActions.m");
            signatures = validationStepSignatures(steps);

            testCase.verifyTrue(any(signatures == "apps/image_measurement|false"), ...
                "Packaged app source changes should run owning family app tests.");
            testCase.verifyTrue(any(signatures == ...
                "gui/apps/image_measurement/batch_crop|true"), ...
                "Packaged app source changes should run the matching app GUI test folder.");
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
                "docs/apps/README.md", ...
                "tests/runner/labkitArtifactPaths.m"]);
            signatures = validationStepSignatures(steps);

            testCase.verifyEqual(sort(signatures), ...
                sort(["project/docs|false", "project/build|false"]), ...
                "Docs and runner changes should keep their two focused contracts.");
            testCase.verifyFalse(any([steps.IncludeGui]), ...
                "Docs and runner changes should not trigger GUI validation.");
        end

        function generatedSiteAndRendererRouteToDocumentationChecks(testCase)
            root = setupLabKitTestPath();
            steps = labkitValidationPlanForChangedPaths(root, [ ...
                "site/reference/api/labkit/image/readFiles.html", ...
                "tools/docs/renderLabKitDocs.m"]);
            testCase.verifyEqual(validationStepSignatures(steps), ...
                "project/docs|false", ...
                "Generated site and renderer changes should use documentation guardrails.");
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

        function changedValidationPlanRoutesToolsToProject(testCase)
            root = setupLabKitTestPath();

            steps = labkitValidationPlanForChangedPaths(root, [
                "tools/profiling/profileLabKitTarget.m"
                "tools/profiling/private/profileLabKitPayload.m"]);
            signatures = validationStepSignatures(steps);

            testCase.verifyEqual(signatures, "project|false", ...
                "Maintainer tools should run project guardrails, not " + ...
                "the full non-GUI suite.");
        end

        function changedValidationPlanCompressesCoveredGuiTargets(testCase)
            root = setupLabKitTestPath();

            steps = labkitValidationPlanForChangedPaths(root, [ ...
                "+labkit/+ui/+runtime/private/runAppBusyCallback.m", ...
                "tests/cases/gui/apps/image_measurement/batch_crop/GuiLayoutBatchCropTest.m"]);
            signatures = validationStepSignatures(steps);

            testCase.verifyTrue(any(signatures == "gui/apps|true"), ...
                "Broad downstream GUI coverage should cover the changed app GUI test.");
            testCase.verifyTrue(all(arrayfun(@(step) isempty(step.Files), steps)), ...
                "A covered exact test-file step should be removed from the plan.");
        end

        function buildTaskCatalogStaysCompactAndDiscoveryDriven(testCase)
            root = setupLabKitTestPath();
            catalog = labkitBuildTaskCatalog();

            expectedTasks = ["changed", "changedFast", "docs", "docsCheck", ...
                "headless", "gui", "coverage", "listTasks"];
            publicTasks = [catalog([catalog.Visibility] == "public").Name];
            testCase.verifyEqual(publicTasks, expectedTasks, ...
                "Build task catalog should expose a compact public task set.");

            ciTasks = [catalog([catalog.Visibility] == "ci").Name];
            testCase.verifyEmpty(ciTasks, ...
                "CI should call public build tasks rather than maintaining CI-only buildfile tasks.");

        end

        function guiBuildTaskRunsHiddenByDefault(testCase)
            setupLabKitTestPath();
            taskSpecs = labkitBuildTaskCatalog();
            guiSpec = taskSpecs([taskSpecs.Name] == "gui");
            testCase.assertEqual(numel(guiSpec), 1, ...
                "Build task catalog should contain one gui task spec.");
            testCase.verifyEqual(guiSpec.GuiMode, "hidden", ...
                "buildtool gui should keep automated GUI windows hidden by default.");
        end

        function testFilesUseKnownTags(testCase)
            root = setupLabKitTestPath();
            allowedTags = ["Unit", "Integration", "GUI", "Structural", ...
                "Workflow", "Gesture", "Style", "Smoke"];
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
        '(?m)^[ \t]*buildtool[ \t]+([A-Za-z][A-Za-z0-9_]*)[ \t]*$', ...
        'tokens');
    tasks = strings(1, numel(tokens));
    for k = 1:numel(tokens)
        tasks(k) = string(tokens{k}{1});
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

    block = normalizeLineEndings(blocks{1}{1});
    tokens = regexp(block, ...
        '(?m)^buildtool[ \t]+([A-Za-z][A-Za-z0-9_]*)[ \t]*$', 'tokens');
    tasks = strings(1, numel(tokens));
    for k = 1:numel(tokens)
        tasks(k) = string(tokens{k}{1});
    end
end

function content = normalizeLineEndings(content)
    content = strrep(content, sprintf('\r\n'), sprintf('\n'));
    content = strrep(content, sprintf('\r'), sprintf('\n'));
end

function verifyTaskSubset(testCase, tasks, catalogNames, label)
    missing = setdiff(tasks, catalogNames);
    testCase.verifyTrue(isempty(missing), ...
        label + " not in buildfile catalog: " + strjoin(missing, ", "));
end

function tf = taskSpecMapsToKnownTests(root, spec)
    if strlength(spec.Plan) > 0
        tf = any(lower(spec.Plan) == ["changed", "changedfast"]);
        return;
    end

    suites = lower(spec.Suites);
    tests = spec.Tests;
    tags = spec.Tags;
    suiteOk = isempty(suites) || all(ismember(suites, knownSuiteTargets(root)));
    testOk = isempty(tests) || taskSelectorsExist(root, suites, tests);
    tagOk = isempty(tags) || all(ismember(tags, knownRunnerTags()));
    tf = suiteOk && testOk && tagOk;
end

function tf = taskSelectorsExist(root, suites, tests)
    output = listLabKitTestsQuietly( ...
        "Suites", suites, "Tests", tests, "RunName", "task_spec_probe");
    tf = output.count > 0;
end

function targets = knownSuiteTargets(root)
    casesRoot = fullfile(root, "tests", "cases");
    folders = collectTestFolders(casesRoot);
    targets = "gui";
    for k = 1:numel(folders)
        key = lower(relativePath(casesRoot, folders(k)));
        key = erase(key, "unit/");
        key = erase(key, "contract/");
        if startsWith(key, "gui/")
            targets(end+1) = key;
            targets = [targets, suiteAncestors(key)];
        elseif key ~= "gui"
            targets(end+1) = key;
            targets = [targets, suiteAncestors(key)];
        end
    end
    targets = unique(targets(strlength(targets) > 0), "stable");
end

function ancestors = suiteAncestors(key)
    parts = split(string(key), "/").';
    ancestors = strings(1, 0);
    for k = 1:(numel(parts) - 1)
        ancestors(end+1) = strjoin(parts(1:k), "/");
    end
end

function tags = knownRunnerTags()
    tags = ["Unit", "Integration", "GUI", "Structural", ...
        "Workflow", "Gesture", "Style", "Smoke"];
end

function folders = collectTestFolders(root)
    files = labkitTestTreeMFiles(root);
    files = files(endsWith(files, "Test.m"));
    folders = strings(1, numel(files));
    for k = 1:numel(files)
        folders(k) = string(fileparts(files(k)));
    end
    folders = unique(folders, "stable");
end

function files = collectTestFiles(root)
    files = labkitTestTreeMFiles(root);
    files = files(endsWith(files, "Test.m"));
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
