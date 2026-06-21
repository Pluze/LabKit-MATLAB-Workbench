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
            expectedLabels = [
                "label: Unit Tests - LabKit"
                "label: Unit Tests - Apps"
                "label: Unit Tests - Project"
                "label: Integration Tests - Apps"
                "label: Integration Tests - Project"];
            for k = 1:numel(expectedLabels)
                testCase.verifyTrue(contains(shardJob, expectedLabels(k)), ...
                    'CI matrix should include shard: ' + expectedLabels(k));
            end
            testCase.verifyTrue(contains(shardJob, "matlab-actions/run-command"), ...
                'CI shards should call the runner directly instead of one serial build task.');
            testCase.verifyTrue(contains(shardJob, '"HtmlReport", false'), ...
                'CI shards should skip HTML reports to reduce wall-clock time.');
            testCase.verifyFalse(contains(shardJob, "tasks: headless"), ...
                'Push/PR CI should not collapse non-GUI validation into one serial headless task.');
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

        function ciRepositoryStateChecksStayOutsideMatlab(testCase)
            root = setupLabKitTestPath();
            workflowPath = fullfile(root, ".github", "workflows", ...
                "matlab-tests.yml");
            workflow = string(fileread(workflowPath));
            repositoryHygieneJob = extractWorkflowJob(workflow, ...
                "repository-hygiene");

            testCase.verifyTrue(contains(repositoryHygieneJob, ...
                "Check MATLAB Project metadata is local"), ...
                'Repository metadata checks should run in repository-hygiene.');
            testCase.verifyTrue(contains(repositoryHygieneJob, ...
                "git ls-files -- LabKit.prj resources/project"), ...
                'Tracked MATLAB Project metadata should be checked by git in shell.');
            formerWrapperPath = "scripts/run_" + "matlab_tests";
            testCase.verifyFalse(contains(repositoryHygieneJob, formerWrapperPath), ...
                'CI should not require the former test wrapper scripts.');
            testCase.verifyFalse(contains(workflow, "matlabProjectMetadataStaysLocal"), ...
                'MATLAB tests should not shell out to git for repository metadata.');
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
