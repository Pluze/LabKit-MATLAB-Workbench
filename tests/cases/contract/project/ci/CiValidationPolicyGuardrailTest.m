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
                'Coverage job should only run for manual or scheduled workflows.');
            testCase.verifyTrue(contains(coverageJob, "artifacts/coverage/**"), ...
                'Coverage job should upload coverage artifacts.');
        end

        function ciPushUsesParallelNonGuiShards(testCase)
            root = setupLabKitTestPath();
            workflowPath = fullfile(root, ".github", "workflows", ...
                "matlab-tests.yml");
            workflow = string(fileread(workflowPath));
            shardJob = extractWorkflowJob(workflow, "headless-shards");

            testCase.verifyTrue(contains(shardJob, "strategy:"), ...
                'Push/PR MATLAB validation should use a matrix for parallelism.');
            expectedTasks = [
                "ciUnitLabKit"
                "ciUnitApps"
                "ciUnitProject"
                "ciIntegrationApps"
                "ciIntegrationProject"];
            for k = 1:numel(expectedTasks)
                testCase.verifyTrue(contains(shardJob, "task: " + expectedTasks(k)), ...
                    'CI matrix should include build task: ' + expectedTasks(k));
            end
            testCase.verifyTrue(contains(shardJob, "matlab-actions/run-build"), ...
                'CI shards should call buildfile tasks through run-build.');
            testCase.verifyFalse(contains(shardJob, "tasks: headless"), ...
                'Push/PR CI should not collapse non-GUI validation into one serial headless task.');
        end

        function ciWorkflowUsesBuildTasksInsteadOfRunnerSelectors(testCase)
            root = setupLabKitTestPath();
            workflowPath = fullfile(root, ".github", "workflows", ...
                "matlab-tests.yml");
            workflow = string(fileread(workflowPath));
            shardJob = extractWorkflowJob(workflow, "headless-shards");
            buildTasks = workflowBuildTasks(shardJob);
            catalogTasks = buildfileTaskNames(root);

            testCase.verifyFalse(contains(shardJob, "matlab-actions/run-command"), ...
                'CI shards should not use run-command for test execution.');
            testCase.verifyFalse(contains(shardJob, "runLabKitTests("), ...
                'CI workflow should not call the low-level runner directly.');
            testCase.verifyFalse(contains(shardJob, 'addpath("tests")'), ...
                'CI workflow should not manage runner path setup directly.');
            testCase.verifyFalse(~isempty(regexp(char(shardJob), ...
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

        function ciPushAndPullRequestsRunOnAllBranches(testCase)
            root = setupLabKitTestPath();
            workflowPath = fullfile(root, ".github", "workflows", ...
                "matlab-tests.yml");
            workflow = char(fileread(workflowPath));

            testCase.verifyTrue(isempty(regexp(workflow, ...
                '(?m)^  push:\s*\n\s+branches:', 'once')), ...
                'Push workflows should run on every branch, not only main.');
            testCase.verifyTrue(isempty(regexp(workflow, ...
                '(?m)^  pull_request:\s*\n\s+branches:', 'once')), ...
                'Pull request workflows should run for every target branch.');
        end

        function ciMatlabJobsHaveTimeouts(testCase)
            root = setupLabKitTestPath();
            workflowPath = fullfile(root, ".github", "workflows", ...
                "matlab-tests.yml");
            workflow = string(fileread(workflowPath));
            jobNames = ["headless-shards", "coverage", "gui"];

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
            jobNames = ["headless-shards", "coverage", "gui"];

            for k = 1:numel(jobNames)
                job = extractWorkflowJob(workflow, jobNames(k));
                testCase.verifyTrue(contains(job, "fetch-depth: 2"), ...
                    "CI MATLAB checkout should keep HEAD^ available: " + jobNames(k));
            end
        end
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
