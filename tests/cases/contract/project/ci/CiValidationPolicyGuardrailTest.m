classdef CiValidationPolicyGuardrailTest < matlab.unittest.TestCase
    %CIVALIDATIONPOLICYGUARDRAILTEST Guard the clean-room CI and release policy.

    methods (Test, TestTags = {'Integration', 'Style'})
        function ordinaryCiUsesCrossPlatformCleanRoomSuite(testCase)
            root = setupLabKitTestPath();
            workflow = readWorkflow(root, "ci.yml");
            pushEvent = extractWorkflowEvent(workflow, "push");
            pullRequestEvent = extractWorkflowEvent(workflow, "pull_request");

            testCase.verifyTrue(contains(pushEvent, "branches:") && ...
                contains(pushEvent, "- main"), ...
                "Ordinary CI should validate main pushes.");
            testCase.verifyTrue(contains(pullRequestEvent, "branches:") && ...
                contains(pullRequestEvent, "- main"), ...
                "Ordinary CI should validate pull requests targeting main.");
            testCase.verifyFalse(contains(workflow, "workflow_dispatch:") || ...
                contains(workflow, "workflow_call:") || ...
                contains(workflow, "schedule:"), ...
                "Ordinary CI should not mix manual, reusable, or scheduled orchestration.");
            testCase.verifyTrue(contains(workflow, ...
                "github.event.pull_request.head.sha || github.sha"), ...
                "Concurrent CI runs should be grouped by candidate commit.");
            testCase.verifyFalse(contains(workflow, "contents: write"), ...
                "Ordinary CI must remain read-only.");
        end

        function ciRunsHeadlessAndGuiOnEveryPlatform(testCase)
            root = setupLabKitTestPath();
            workflow = readWorkflow(root, "ci.yml");
            headlessJob = extractWorkflowJob(workflow, "headless-platforms");
            guiJob = extractWorkflowJob(workflow, "gui-platforms");
            requiredRunners = ["ubuntu-latest", "macos-14", "windows-latest"];

            for runner = requiredRunners
                testCase.verifyTrue(contains(headlessJob, runner), ...
                    "Headless clean-room validation is missing " + runner + ".");
                testCase.verifyTrue(contains(guiJob, runner), ...
                    "Hidden GUI clean-room validation is missing " + runner + ".");
            end
            testCase.verifyTrue(contains(headlessJob, "tasks: headless"), ...
                "Each platform should run the public headless task.");
            testCase.verifyTrue(contains(guiJob, "tasks: gui"), ...
                "Each platform should run the public hidden-GUI task.");
            testCase.verifyTrue(contains(headlessJob, "fail-fast: false") && ...
                contains(guiJob, "fail-fast: false"), ...
                "One platform failure should not hide evidence from the others.");
        end

        function requiredJobsInstallOnlyMatlab(testCase)
            root = setupLabKitTestPath();
            workflow = readWorkflow(root, "ci.yml");
            requiredJobs = ["headless-platforms", "gui-platforms"];

            for jobName = requiredJobs
                job = extractWorkflowJob(workflow, jobName);
                testCase.verifyTrue(contains(job, ...
                    "uses: matlab-actions/setup-matlab@v3"), ...
                    "MATLAB setup is missing from " + jobName + ".");
                testCase.verifyFalse(contains(job, "products:"), ...
                    "Base MATLAB jobs must not install Toolboxes: " + jobName + ".");
            end
        end

        function noCiPathInstallsOptionalToolboxes(testCase)
            root = setupLabKitTestPath();
            workflow = readWorkflow(root, "ci.yml");
            testCase.verifyFalse(contains(workflow, "products:"), ...
                "CI runners must install MATLAB only and no optional Toolboxes.");
            testCase.verifyFalse(contains(workflow, "dependencyAudit") || ...
                contains(workflow, "requiredFilesAndProducts"), ...
                "CI should prove the runtime directly, not reverse-audit installed products.");
            testCase.verifyFalse(contains(workflow, "tasks: coverage"), ...
                "A report-only coverage rerun should remain an explicit local task.");
        end

        function releaseRequiresManualTestingAndValidationBeforeTag(testCase)
            root = setupLabKitTestPath();
            workflow = readWorkflow(root, "release.yml");
            requestJob = extractWorkflowJob(workflow, "validate-request");
            draftJob = extractWorkflowJob(workflow, "create-draft");

            testCase.verifyTrue(contains(workflow, "workflow_dispatch:") && ...
                ~contains(workflow, "push:") && ~contains(workflow, "schedule:"), ...
                "Release creation should begin only through an explicit developer dispatch.");
            testCase.verifyTrue(contains(workflow, ...
                "manual_validation_confirmed:") && ...
                contains(requestJob, "MANUAL_VALIDATION_CONFIRMED") && ...
                contains(requestJob, "refs/heads/main"), ...
                "Release should require manual App testing and a main-branch candidate.");
            testCase.verifyTrue(contains(requestJob, ...
                "^v[0-9]+\.[0-9]+\.[0-9]+$"), ...
                "New release tags should use vX.Y.Z.");
            testCase.verifyTrue(contains(requestJob, ...
                "actions/workflows/ci.yml/runs?head_sha=${RELEASE_SHA}") && ...
                contains(requestJob, "event=push") && ...
                contains(requestJob, "status=success"), ...
                "Release should require successful CI for the exact main commit.");
            testCase.verifyTrue(contains(draftJob, "needs: validate-request") && ...
                contains(draftJob, "contents: write"), ...
                "Tag and release writes must wait for request and CI validation.");
            testCase.verifyTrue(contains(draftJob, "git tag --annotate") && ...
                contains(draftJob, 'git show "${RELEASE_TAG}:labkit_launcher.m"') && ...
                contains(draftJob, "git push origin"), ...
                "Release asset bytes must come from the validated tag blob.");
            testCase.verifyTrue(contains(draftJob, "gh release create") && ...
                contains(draftJob, "--verify-tag") && ...
                contains(draftJob, "--draft") && ...
                contains(draftJob, "gh release verify-asset"), ...
                "Automation should stop at a verified draft for developer review.");
            testCase.verifyFalse(contains(workflow, "/git/refs") || ...
                contains(workflow, "--draft=false"), ...
                "Release must not use raw-ref publication or auto-publish the draft.");
        end

        function workflowsCallOnlyPublicBuildTasks(testCase)
            root = setupLabKitTestPath();
            workflowNames = ["ci.yml", "release.yml"];
            workflow = "";
            for name = workflowNames
                workflow = workflow + newline + readWorkflow(root, name);
            end
            buildTasks = workflowBuildTasks(workflow);
            catalogTasks = buildfileTaskNames();

            testCase.verifyFalse(contains(workflow, "matlab-actions/run-command"), ...
                "CI should execute stable build tasks, not free-form MATLAB commands.");
            testCase.verifyFalse(contains(workflow, "runLabKitTests("), ...
                "Workflow YAML should not call the low-level runner.");
            testCase.verifyNotEmpty(buildTasks, ...
                "The reusable suite should expose validation through build tasks.");
            testCase.verifyEmpty(setdiff(buildTasks, catalogTasks), ...
                "Unknown workflow build tasks: " + ...
                strjoin(setdiff(buildTasks, catalogTasks), ", "));
        end

        function matlabJobsPreserveFailureDiagnostics(testCase)
            root = setupLabKitTestPath();
            workflow = readWorkflow(root, "ci.yml");
            jobNames = ["headless-platforms", "gui-platforms"];

            for jobName = jobNames
                job = extractWorkflowJob(workflow, jobName);
                testCase.verifyGreaterThanOrEqual(count(job, "timeout-minutes:"), 2, ...
                    "MATLAB step should time out before artifact upload job: " + jobName);
                testCase.verifyTrue(contains(job, "--active-test"), ...
                    "Failure summary should identify the active test: " + jobName);
                testCase.verifyTrue(contains(job, "fetch-depth: 2"), ...
                    "Validation should retain HEAD^ for diff contracts: " + jobName);
                testCase.verifyTrue(contains(job, "actions/upload-artifact@v7"), ...
                    "Validation should preserve diagnostic artifacts: " + jobName);
            end
        end

        function ciBuildfileAvoidsUnlicensedChildMatlabWorkers(testCase)
            root = setupLabKitTestPath();
            buildfile = string(fileread(fullfile(root, "buildfile.m")));
            orchestrator = string(fileread(fullfile(root, "tests", ...
                "runner", "labkitRunInternalShards.m")));

            testCase.verifyTrue(contains(buildfile, ...
                "labkitRunInternalShards(root, spec, args)") && ...
                contains(orchestrator, "GITHUB_ACTIONS") && ...
                contains(orchestrator, "isGitHubActions()"), ...
                "GitHub-hosted MATLAB validation should stay single-process.");
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
                "A filtered assumption should not fail its validation job.");
            testCase.verifyTrue(labkitOfficialResultsHaveFailures(failed), ...
                "A genuine test failure must fail its validation job.");
        end
    end
end

function workflow = readWorkflow(root, name)
    workflow = string(fileread(fullfile(root, ".github", "workflows", name)));
end

function event = extractWorkflowEvent(workflow, eventName)
    event = extractIndentedBlock(workflow, "  " + eventName + ":");
end

function job = extractWorkflowJob(workflow, jobName)
    job = extractIndentedBlock(workflow, "  " + jobName + ":");
end

function block = extractIndentedBlock(text, header)
    lines = splitlines(string(text));
    startLine = find(lines == header, 1);
    if isempty(startLine)
        block = "";
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
        if strlength(line) > 0 && ~startsWith(line, " ")
            stopLine = k - 1;
            break;
        end
    end
    block = strjoin(lines(startLine:stopLine), newline);
end

function tasks = workflowBuildTasks(workflow)
    tokens = regexp(char(workflow), ...
        '(?m)^\s+tasks:\s*([A-Za-z][A-Za-z0-9_]*)\s*$', "tokens");
    tasks = strings(1, numel(tokens));
    for k = 1:numel(tokens)
        tasks(k) = string(tokens{k}{1});
    end
    tasks = unique(tasks, "stable");
end

function names = buildfileTaskNames()
    catalog = labkitBuildTaskCatalog();
    names = unique([catalog.Name], "stable");
end
