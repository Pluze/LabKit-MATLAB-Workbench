classdef CiValidationPolicyGuardrailTest < matlab.unittest.TestCase
    %CIVALIDATIONPOLICYGUARDRAILTEST Guardrails for CI validation policy.

    methods (Test, TestTags = {'Integration', 'Style'})
        function ciCoverageRunsOnlyOnManualScheduledOrReleaseWorkflows(testCase)
            root = setupLabKitTestPath();
            workflowPath = fullfile(root, ".github", "workflows", ...
                "matlab-tests.yml");
            workflow = string(fileread(workflowPath));

            testCase.verifyFalse(contains(workflow, "tasks: headless coverage"), ...
                'PR headless job should not duplicate coverage execution.');
            testCase.verifyTrue(contains(workflow, "tasks: coverage"), ...
                'Coverage should remain available through a dedicated job.');
            coverageJob = extractWorkflowJob(workflow, "coverage");
            testCase.verifyTrue(contains(coverageJob, ...
                "github.event_name == 'workflow_dispatch' || github.event_name == 'schedule' || startsWith(github.ref, 'refs/tags/v')"), ...
                'Coverage job should run only for manual, scheduled, or release-tag workflows.');
            testCase.verifyTrue(contains(coverageJob, "artifacts/coverage/**"), ...
                'Coverage job should upload coverage artifacts.');
        end

        function ciPushUsesPublicHeadlessTask(testCase)
            root = setupLabKitTestPath();
            workflowPath = fullfile(root, ".github", "workflows", ...
                "matlab-tests.yml");
            workflow = string(fileread(workflowPath));
            headlessJob = extractWorkflowJob(workflow, "headless");

            testCase.verifyTrue(contains(headlessJob, "tasks: headless"), ...
                'CI should call the public headless build task.');
            testCase.verifyTrue(contains(headlessJob, "artifacts/test-results/*/junit.xml"), ...
                'CI summary should handle buildfile-managed internal shards.');
            testCase.verifyFalse(contains(headlessJob, "LABKIT_TEST_SHARD_"), ...
                'CI workflow should not own shard environment variables.');
            testCase.verifyFalse(contains(headlessJob, "matrix:"), ...
                'CI workflow should not maintain a headless shard matrix.');
            testCase.verifyFalse(contains(headlessJob, "ciUnit"), ...
                'CI workflow should not call CI-only unit shard tasks.');
            testCase.verifyFalse(contains(headlessJob, "ciIntegration"), ...
                'CI workflow should not call CI-only integration shard tasks.');
        end

        function ciBuildfileAvoidsUnlicensedChildMatlabWorkers(testCase)
            root = setupLabKitTestPath();
            buildfilePath = fullfile(root, "buildfile.m");
            buildfile = string(fileread(buildfilePath));

            testCase.verifyTrue(contains(buildfile, "GITHUB_ACTIONS"), ...
                'Buildfile-managed worker routing should detect GitHub Actions.');
            testCase.verifyTrue(contains(buildfile, "isGitHubActions()"), ...
                'Headless build routing should stay serial under GitHub Actions unless worker licensing is proven.');
        end

        function ciWorkflowUsesBuildTasksInsteadOfRunnerSelectors(testCase)
            root = setupLabKitTestPath();
            workflowPath = fullfile(root, ".github", "workflows", ...
                "matlab-tests.yml");
            workflow = string(fileread(workflowPath));
            headlessJob = extractWorkflowJob(workflow, "headless");
            buildTasks = workflowBuildTasks(headlessJob);
            catalogTasks = buildfileTaskNames(root);

            testCase.verifyFalse(contains(headlessJob, "matlab-actions/run-command"), ...
                'CI should not use run-command for test execution.');
            testCase.verifyFalse(contains(headlessJob, "runLabKitTests("), ...
                'CI workflow should not call the low-level runner directly.');
            testCase.verifyFalse(contains(headlessJob, 'addpath("tests")'), ...
                'CI workflow should not manage runner path setup directly.');
            testCase.verifyFalse(~isempty(regexp(char(headlessJob), ...
                '"Tests"\s*,\s*\[', 'once')), ...
                'CI workflow should not maintain long-lived test-class selectors.');
            testCase.verifyEmpty(setdiff(buildTasks, catalogTasks), ...
                "CI workflow should reference buildfile tasks only: " + ...
                strjoin(setdiff(buildTasks, catalogTasks), ", "));
        end

        function runnerRejectsUnmatchedTestSelectors(testCase)
            setupLabKitTestPath();
            testCase.verifyError(@() runLabKitTests( ...
                "Tests", "DefinitelyMissingLabKitSelector", ...
                "ListOnly", true, ...
                "HtmlReport", false, ...
                "RunName", "missing-selector-probe"), ...
                "LabKit:Tests:UnmatchedTestSelector");
        end

        function ciTriggersAvoidDuplicateBranchPrRuns(testCase)
            root = setupLabKitTestPath();
            workflowPath = fullfile(root, ".github", "workflows", ...
                "matlab-tests.yml");
            workflow = char(fileread(workflowPath));
            pushEvent = extractWorkflowEvent(workflow, "push");
            pullRequestEvent = extractWorkflowEvent(workflow, "pull_request");

            testCase.verifyTrue(contains(pushEvent, "branches:"), ...
                'Push workflows should target branch refs so tag pushes do not duplicate CI.');
            testCase.verifyTrue(~isempty(regexp(char(pushEvent), ...
                "(?m)^\s+- main\s*$", 'once')), ...
                'Push workflows should run only on main so branch pushes do not duplicate pull-request CI.');
            testCase.verifyTrue(contains(pullRequestEvent, "branches:") && ...
                ~isempty(regexp(char(pullRequestEvent), "(?m)^\s+- main\s*$", 'once')), ...
                'Pull request workflows should target main PRs.');
            testCase.verifyGreaterThan(strlength(pullRequestEvent), 0, ...
                'Pull request workflow trigger should remain present.');
            testCase.verifyTrue(contains(workflow, ...
                "github.event.pull_request.head.sha || github.sha"), ...
                'CI concurrency should group branch and PR events by commit SHA.');
        end

        function releaseTagsRunAllTestProjectsBeforePublishing(testCase)
            root = setupLabKitTestPath();
            workflowPath = fullfile(root, ".github", "workflows", ...
                "matlab-tests.yml");
            workflow = string(fileread(workflowPath));
            pushEvent = extractWorkflowEvent(char(workflow), "push");
            coverageJob = extractWorkflowJob(workflow, "coverage");
            guiJob = extractWorkflowJob(workflow, "gui");
            gateJob = extractWorkflowJob(workflow, "release-test-gate");

            testCase.verifyTrue(contains(pushEvent, "tags:") && ...
                contains(pushEvent, "'v*.*.*'"), ...
                'Release candidate tag pushes should trigger validation.');
            testCase.verifyTrue(contains(coverageJob, "startsWith(github.ref, 'refs/tags/v')") && ...
                contains(guiJob, "startsWith(github.ref, 'refs/tags/v')"), ...
                'Release tag validation should include coverage and GUI jobs.');
            testCase.verifyTrue(contains(gateJob, "headless") && ...
                contains(gateJob, "coverage") && contains(gateJob, "gui"), ...
                'Release Test Gate should depend on all public test projects.');
        end

        function ciMatlabJobsHaveTimeouts(testCase)
            root = setupLabKitTestPath();
            workflowPath = fullfile(root, ".github", "workflows", ...
                "matlab-tests.yml");
            workflow = string(fileread(workflowPath));
            jobNames = ["headless", "coverage", "gui"];

            for k = 1:numel(jobNames)
                job = extractWorkflowJob(workflow, jobNames(k));
                testCase.verifyTrue(contains(job, "timeout-minutes:"), ...
                    "CI MATLAB job should have an explicit timeout: " + jobNames(k));
            end
        end

        function ciMatlabJobsFetchParentCommit(testCase)
            root = setupLabKitTestPath();
            workflowPath = fullfile(root, ".github", "workflows", ...
                "matlab-tests.yml");
            workflow = string(fileread(workflowPath));
            jobNames = ["headless", "coverage", "gui"];

            for k = 1:numel(jobNames)
                job = extractWorkflowJob(workflow, jobNames(k));
                testCase.verifyTrue(contains(job, "fetch-depth: 2"), ...
                    "CI MATLAB checkout should keep HEAD^ available: " + jobNames(k));
            end
        end
    end
end

function event = extractWorkflowEvent(workflow, eventName)
    lines = splitlines(string(workflow));
    eventHeader = "  " + eventName + ":";
    startLine = find(lines == eventHeader, 1);
    if isempty(startLine)
        event = "";
        return;
    end

    stopLine = numel(lines);
    for k = startLine + 1:numel(lines)
        line = lines(k);
        trimmed = strtrim(line);
        if strlength(trimmed) == 0
            continue;
        end
        if ~startsWith(line, " ")
            stopLine = k - 1;
            break;
        end
        if startsWith(line, "  ") && ~startsWith(line, "    ") && ...
                endsWith(line, ":")
            stopLine = k - 1;
            break;
        end
    end
    event = strjoin(lines(startLine:stopLine), newline);
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

function tasks = workflowBuildTasks(workflow)
    tokens = regexp(char(workflow), '(?m)^\s+task:\s*([A-Za-z][A-Za-z0-9_]*)\s*$', ...
        'tokens');
    tasks = strings(1, numel(tokens));
    for k = 1:numel(tokens)
        tasks(k) = string(tokens{k}{1});
    end
    tasks = unique(tasks, "stable");
end

function names = buildfileTaskNames(root)
    content = fileread(fullfile(root, "buildfile.m"));
    tokens = regexp(content, 'taskSpec\("([^"]+)"', 'tokens');
    names = strings(1, numel(tokens));
    for k = 1:numel(tokens)
        names(k) = string(tokens{k}{1});
    end
    names = unique(names, "stable");
end
