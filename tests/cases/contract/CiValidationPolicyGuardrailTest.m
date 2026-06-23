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

        function ciWorkflowTestSelectorsResolveToKnownClasses(testCase)
            root = setupLabKitTestPath();
            workflowPath = fullfile(root, ".github", "workflows", ...
                "matlab-tests.yml");
            workflow = string(fileread(workflowPath));
            selectors = workflowTestSelectors(workflow);
            knownClasses = knownTestClassNames(root);

            testCase.verifyNotEmpty(selectors, ...
                'CI workflow should declare explicit test-class selectors for integration shards.');
            testCase.verifyEmpty(setdiff(selectors, knownClasses), ...
                "CI workflow should not reference missing test classes: " + ...
                strjoin(setdiff(selectors, knownClasses), ", "));

            requiredSelectors = [
                "VersionChangeGuardrailTest"
                "RepositoryHygieneGuardrailTest"
                "TestCompatibilityGuardrailTest"];
            testCase.verifyEmpty(setdiff(requiredSelectors, selectors), ...
                "CI workflow should include current release and hygiene guardrails: " + ...
                strjoin(setdiff(requiredSelectors, selectors), ", "));
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

function selectors = workflowTestSelectors(workflow)
    blocks = regexp(char(workflow), '"Tests"\s*,\s*\[([^\]]*)\]', 'tokens');
    selectors = strings(0, 1);
    for k = 1:numel(blocks)
        names = regexp(blocks{k}{1}, '"([^"]+)"', 'tokens');
        for n = 1:numel(names)
            selectors(end+1, 1) = string(names{n}{1});
        end
    end
    selectors = unique(selectors, "stable");
end

function names = knownTestClassNames(root)
    listing = dir(fullfile(root, "tests", "cases", "**", "*.m"));
    names = strings(0, 1);
    for k = 1:numel(listing)
        if ~listing(k).isdir
            [~, name] = fileparts(listing(k).name);
            names(end+1, 1) = string(name);
        end
    end
    names = unique(names, "stable");
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
