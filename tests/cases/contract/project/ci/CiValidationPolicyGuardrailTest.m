classdef CiValidationPolicyGuardrailTest < matlab.unittest.TestCase
    %CIVALIDATIONPOLICYGUARDRAILTEST Guardrails for CI validation policy.

    methods (Test, TestTags = {'Integration', 'Style'})
        function ciCoverageRunsOnlyOnManualOrScheduledWorkflows(testCase)
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
                "github.event_name == 'workflow_dispatch' || github.event_name == 'schedule'"), ...
                'Coverage job should run only for manual or scheduled workflows.');
            testCase.verifyFalse(contains(coverageJob, "refs/tags/"), ...
                'Coverage should validate a release candidate before its tag exists.');
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

        function ciBaseMatlabRunsOnManualOrScheduledWorkflows(testCase)
            root = setupLabKitTestPath();
            workflowPath = fullfile(root, ".github", "workflows", ...
                "matlab-tests.yml");
            workflow = string(fileread(workflowPath));
            baseMatlabJob = extractWorkflowJob(workflow, "base-matlab");

            testCase.verifyTrue(contains(baseMatlabJob, "tasks: baseMatlab"), ...
                'CI should call the public Base MATLAB compatibility task.');
            testCase.verifyTrue(contains(baseMatlabJob, ...
                "github.event_name == 'workflow_dispatch' || github.event_name == 'schedule'"), ...
                ['The broad MATLAB product-ownership scan should run for ' ...
                'scheduled validation and release candidates.']);
            testCase.verifyTrue(contains(baseMatlabJob, ...
                "artifacts/test-results/baseMatlab/junit.xml"), ...
                'Base MATLAB validation should publish its official JUnit result.');
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
            buildTasks = workflowBuildTasks(workflow);
            catalogTasks = buildfileTaskNames(root);

            testCase.verifyFalse(contains(workflow, "matlab-actions/run-command"), ...
                'CI should not use run-command for test execution.');
            testCase.verifyFalse(contains(workflow, "runLabKitTests("), ...
                'CI workflow should not call the low-level runner directly.');
            testCase.verifyFalse(contains(workflow, 'addpath("tests")'), ...
                'CI workflow should not manage runner path setup directly.');
            testCase.verifyFalse(~isempty(regexp(char(workflow), ...
                '"Tests"\s*,\s*\[', 'once')), ...
                'CI workflow should not maintain long-lived test-class selectors.');
            testCase.verifyNotEmpty(buildTasks, ...
                'CI workflow should expose its validation through public build tasks.');
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

        function runnerDoesNotTreatAssumptionSkipsAsFailures(testCase)
            setupLabKitTestPath();
            skipped = struct("Passed", false, "Failed", false, "Incomplete", true);
            failed = struct("Passed", false, "Failed", true, "Incomplete", true);

            testCase.verifyFalse(labkitOfficialResultsHaveFailures(skipped), ...
                "A filtered assumption is incomplete but should not fail its shard.");
            testCase.verifyTrue(labkitOfficialResultsHaveFailures(failed), ...
                "A genuine failed result must still fail its shard.");
        end

        function ciTriggersAvoidDuplicateBranchPrRuns(testCase)
            root = setupLabKitTestPath();
            workflowPath = fullfile(root, ".github", "workflows", ...
                "matlab-tests.yml");
            workflow = char(fileread(workflowPath));
            pushEvent = extractWorkflowEvent(workflow, "push");
            pullRequestEvent = extractWorkflowEvent(workflow, "pull_request");

            testCase.verifyTrue(contains(pushEvent, "branches:"), ...
                'Push workflows should target branch refs.');
            testCase.verifyFalse(contains(pushEvent, "tags:"), ...
                'Release tags should be created after validation, not trigger validation.');
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

        function validatedManualReleaseCreatesTagAfterAllTestProjects(testCase)
            root = setupLabKitTestPath();
            workflowPath = fullfile(root, ".github", "workflows", ...
                "matlab-tests.yml");
            workflow = string(fileread(workflowPath));
            pushEvent = extractWorkflowEvent(char(workflow), "push");
            coverageJob = extractWorkflowJob(workflow, "coverage");
            guiJob = extractWorkflowJob(workflow, "gui");
            baseMatlabJob = extractWorkflowJob(workflow, "base-matlab");
            gateJob = extractWorkflowJob(workflow, "release-test-gate");
            tagJob = extractWorkflowJob(workflow, "release-tag");

            testCase.verifyFalse(contains(pushEvent, "tags:"), ...
                'An unvalidated release tag must not exist merely to trigger tests.');
            testCase.verifyTrue(contains(workflow, "release_tag:") && ...
                contains(workflow, "inputs.release_tag"), ...
                'Manual release validation should accept one optional release tag.');
            testCase.verifyTrue(contains(coverageJob, "workflow_dispatch") && ...
                contains(guiJob, "workflow_dispatch") && ...
                contains(baseMatlabJob, "workflow_dispatch"), ...
                ['Manual release validation should include Base MATLAB, ' ...
                'coverage, and GUI jobs.']);
            testCase.verifyTrue(contains(gateJob, "headless") && ...
                contains(gateJob, "base-matlab") && ...
                contains(gateJob, "coverage") && contains(gateJob, "gui"), ...
                'Release Test Gate should depend on all public test projects.');
            testCase.verifyTrue(contains(tagJob, "release-test-gate") && ...
                contains(tagJob, "contents: write"), ...
                'Tag creation should require the full release gate and scoped write permission.');
            testCase.verifyTrue(contains(tagJob, "refs/heads/main") && ...
                contains(tagJob, "github.sha") && ...
                contains(tagJob, "refs/tags/${RELEASE_TAG}"), ...
                'The validated tag must point at the dispatched main commit.');
        end

        function ciMatlabJobsHaveTimeouts(testCase)
            root = setupLabKitTestPath();
            workflowPath = fullfile(root, ".github", "workflows", ...
                "matlab-tests.yml");
            workflow = string(fileread(workflowPath));
            jobNames = ["headless", "base-matlab", "coverage", "gui"];

            for k = 1:numel(jobNames)
                job = extractWorkflowJob(workflow, jobNames(k));
                testCase.verifyTrue(contains(job, "timeout-minutes:"), ...
                    "CI MATLAB job should have an explicit timeout: " + jobNames(k));
                testCase.verifyGreaterThanOrEqual(count(job, "timeout-minutes:"), 2, ...
                    "CI MATLAB execution should time out before its job so diagnostics can upload: " + ...
                    jobNames(k));
                testCase.verifyTrue(contains(job, "--active-test"), ...
                    "CI summaries should report the last active test: " + jobNames(k));
            end
        end

        function ciMatlabJobsFetchParentCommit(testCase)
            root = setupLabKitTestPath();
            workflowPath = fullfile(root, ".github", "workflows", ...
                "matlab-tests.yml");
            workflow = string(fileread(workflowPath));
            jobNames = ["headless", "base-matlab", "coverage", "gui"];

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
    tokens = regexp(char(workflow), '(?m)^\s+tasks:\s*([A-Za-z][A-Za-z0-9_]*)\s*$', ...
        'tokens');
    tasks = strings(1, numel(tokens));
    for k = 1:numel(tokens)
        tasks(k) = string(tokens{k}{1});
    end
    tasks = unique(tasks, "stable");
end

function names = buildfileTaskNames(~)
    catalog = labkitBuildTaskCatalog();
    names = unique([catalog.Name], "stable");
end
