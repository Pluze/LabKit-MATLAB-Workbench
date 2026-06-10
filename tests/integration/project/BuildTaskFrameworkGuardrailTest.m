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

        function documentedAndWrapperTasksStayInCatalog(testCase)
            root = setupLabKitTestPath();
            catalog = extractBuildfileCatalog(root);
            catalogNames = catalog.Name;

            docFiles = [ ...
                fullfile(root, "README.md"), ...
                fullfile(root, "docs", "testing.md")];
            for k = 1:numel(docFiles)
                tasks = extractBuildtoolTasks(fileread(docFiles(k)));
                verifyTaskSubset(testCase, tasks, catalogNames, ...
                    "Documented buildtool tasks in " + relativePath(root, docFiles(k)));
            end

            wrapperFiles = [ ...
                fullfile(root, "scripts", "run_matlab_tests.sh"), ...
                fullfile(root, "scripts", "run_matlab_tests.ps1")];
            for k = 1:numel(wrapperFiles)
                tasks = extractWrapperCommonTasks(fileread(wrapperFiles(k)));
                verifyTaskSubset(testCase, tasks, catalogNames, ...
                    "Wrapper help tasks in " + relativePath(root, wrapperFiles(k)));
            end
        end

        function focusedBuildTasksMatchAtLeastOneTest(testCase)
            setupLabKitTestPath();
            taskSpecs = focusedTaskSpecs();
            for k = 1:numel(taskSpecs)
                spec = taskSpecs(k);
                output = runLabKitTests(spec.Args{:}, ...
                    "RunName", spec.Name + "_list", ...
                    "ListOnly", true);
                testCase.verifyGreaterThan(output.count, 0, ...
                    "Focused build task should match tests: " + spec.Name);
            end
        end

        function defaultRunnerSelectionExcludesGuiTests(testCase)
            setupLabKitTestPath();
            output = runLabKitTests( ...
                "IncludeGui", false, ...
                "RunName", "default_list", ...
                "ListOnly", true);

            testCase.verifyGreaterThan(output.count, 0, ...
                'Default non-GUI runner selection should not be empty.');
            testCase.verifyFalse(any(contains(output.tests.Tags, "GUI")), ...
                'Default non-GUI runner selection must not include GUI tests.');
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

        function ciCoverageRunsOnlyOnManualOrScheduledWorkflows(testCase)
            root = setupLabKitTestPath();
            workflowPath = fullfile(root, ".github", "workflows", ...
                "matlab-tests.yml");
            workflow = string(fileread(workflowPath));

            testCase.verifyFalse(contains(workflow, "tasks: testUnit coverage"), ...
                'PR unit job should not duplicate coverage execution.');
            testCase.verifyTrue(contains(workflow, "tasks: coverage"), ...
                'Coverage should remain available through a dedicated job.');
            coverageJob = extractWorkflowJob(workflow, "coverage");
            testCase.verifyTrue(contains(coverageJob, ...
                "github.event_name == 'workflow_dispatch' || github.event_name == 'schedule'"), ...
                'Coverage job should only run for manual or scheduled workflows.');
            testCase.verifyTrue(contains(coverageJob, "artifacts/coverage/**"), ...
                'Coverage job should upload coverage artifacts.');
        end

        function ciRepositoryStateChecksStayOutsideMatlab(testCase)
            root = setupLabKitTestPath();
            workflowPath = fullfile(root, ".github", "workflows", ...
                "matlab-tests.yml");
            workflow = string(fileread(workflowPath));
            shellWrapperJob = extractWorkflowJob(workflow, "shell-wrapper");

            testCase.verifyTrue(contains(shellWrapperJob, ...
                "Check MATLAB Project metadata is local"), ...
                'Repository metadata checks should run in shell-wrapper.');
            testCase.verifyTrue(contains(shellWrapperJob, ...
                "git ls-files -- LabKit.prj resources/project"), ...
                'Tracked MATLAB Project metadata should be checked by git in shell.');
            testCase.verifyFalse(contains(workflow, "matlabProjectMetadataStaysLocal"), ...
                'MATLAB tests should not shell out to git for repository metadata.');
        end

        function ciMatlabJobsHaveTimeouts(testCase)
            root = setupLabKitTestPath();
            workflowPath = fullfile(root, ".github", "workflows", ...
                "matlab-tests.yml");
            workflow = string(fileread(workflowPath));
            jobNames = ["quality", "unit", "coverage", "integration", ...
                "gui-structural", "gui-gesture"];

            for k = 1:numel(jobNames)
                job = extractWorkflowJob(workflow, jobNames(k));
                testCase.verifyTrue(contains(job, "timeout-minutes:"), ...
                    "CI MATLAB job should have an explicit timeout: " + jobNames(k));
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

function tasks = extractWrapperCommonTasks(content)
    content = char(content);
    startIndex = strfind(content, 'Common tasks:');
    stopIndex = strfind(content, 'Removed interface:');
    if isempty(startIndex) || isempty(stopIndex)
        tasks = strings(1, 0);
        return;
    end

    block = content(startIndex(1):stopIndex(1)-1);
    tokens = regexp(block, '(?m)^\s{2}([A-Za-z][A-Za-z0-9_]*)\s*$', ...
        'tokens');
    tasks = strings(1, numel(tokens));
    for k = 1:numel(tokens)
        tasks(k) = string(tokens{k}{1});
    end
    tasks = unique(tasks, 'stable');
end

function verifyTaskSubset(testCase, tasks, catalogNames, label)
    missing = setdiff(tasks, catalogNames);
    testCase.verifyTrue(isempty(missing), ...
        label + " not in buildfile catalog: " + strjoin(missing, ", "));
end

function taskSpecs = focusedTaskSpecs()
    taskSpecs = [ ...
        listTaskSpec("testProject", {"Suites", "project"}), ...
        listTaskSpec("testLabkitDta", {"Suites", "labkit/dta"}), ...
        listTaskSpec("testLabkitBiosignal", {"Suites", "labkit/biosignal"}), ...
        listTaskSpec("testLabkitUi", {"Suites", "labkit/ui", "IncludeGui", false}), ...
        listTaskSpec("testLabkitUiGui", {"Suites", "labkit/ui", "IncludeGui", true}), ...
        listTaskSpec("testAppsElectrochem", {"Suites", "apps/electrochem", "IncludeGui", false}), ...
        listTaskSpec("testAppsElectrochemGui", {"Suites", "apps/electrochem", "IncludeGui", true}), ...
        listTaskSpec("testAppsDicGui", {"Suites", "apps/dic", "IncludeGui", true}), ...
        listTaskSpec("testAppsImageMeasurement", {"Suites", "apps/image_measurement", "IncludeGui", false}), ...
        listTaskSpec("testAppsImageMeasurementGui", {"Suites", "apps/image_measurement", "IncludeGui", true}), ...
        listTaskSpec("testAppsWearableGui", {"Suites", "apps/wearable", "IncludeGui", true}), ...
        listTaskSpec("testAppsGui", {"Suites", "apps", "IncludeGui", true}), ...
        listTaskSpec("testAppsSmokeGui", {"Suites", "apps/smoke", "IncludeGui", true}), ...
        listTaskSpec("testGuiStructural", {"Suites", "gui", "Tags", "Structural", "IncludeGui", true}), ...
        listTaskSpec("testGuiGesture", {"Tags", "Gesture", "IncludeGui", true})];
end

function spec = listTaskSpec(name, args)
    spec = struct("Name", string(name), "Args", {args});
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

function job = extractWorkflowJob(workflow, jobName)
    lines = splitlines(string(workflow));
    jobHeader = "  " + jobName + ":";
    startLine = find(lines == jobHeader, 1);
    if isempty(startLine)
        job = "";
        return;
    end

    stopLine = numel(lines);
    for k = startLine + 1:numel(lines)
        line = lines(k);
        if startsWith(line, "  ") && ~startsWith(line, "    ") && ...
                endsWith(line, ":")
            stopLine = k - 1;
            break;
        end
    end
    job = strjoin(lines(startLine:stopLine), newline);
end

function rel = relativePath(root, filepath)
    rel = replace(string(filepath), "\", "/");
    root = replace(string(root), "\", "/");
    if startsWith(rel, root + "/")
        rel = extractAfter(rel, strlength(root) + 1);
    end
end
