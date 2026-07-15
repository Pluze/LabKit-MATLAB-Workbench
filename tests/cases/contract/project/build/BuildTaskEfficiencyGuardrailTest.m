classdef BuildTaskEfficiencyGuardrailTest < matlab.unittest.TestCase
    %BUILDTASKEFFICIENCYGUARDRAILTEST Guardrails for fast validation routing.

    methods (Test, TestTags = {'Integration', 'Style'})
        function focusedRunnerSupportsDeterministicShards(testCase)
            setupLabKitTestPath();

            allOutput = listLabKitTestsQuietly("Suites", "project/build", ...
                "RunName", "shard_all_probe");
            firstShard = listLabKitTestsQuietly("Suites", "project/build", ...
                "ShardCount", 2, "ShardIndex", 0, ...
                "RunName", "shard_0_probe");
            secondShard = listLabKitTestsQuietly("Suites", "project/build", ...
                "ShardCount", 2, "ShardIndex", 1, ...
                "RunName", "shard_1_probe");

            combined = sort([firstShard.tests.Name; secondShard.tests.Name]);
            testCase.verifyEqual(combined, sort(allOutput.tests.Name), ...
                "Runner shards should cover the selected test set exactly once.");
            testCase.verifyEmpty(intersect(firstShard.tests.Name, ...
                secondShard.tests.Name), ...
                "Runner shards should not overlap.");
        end

        function changedFastValidationPlanUsesRepresentativeAppGuiCoverage(testCase)
            root = setupLabKitTestPath();

            steps = labkitValidationPlanForChangedPaths(root, ...
                "+labkit/+ui/+runtime/runBusy.m", "Mode", "fast");
            signatures = validationStepSignatures(steps);
            tests = validationStepTestSelectors(steps);
            reasons = validationStepReasons(steps);

            testCase.verifyTrue(any(signatures == "labkit_framework/ui|false"), ...
                "Fast changed UI validation should keep reusable UI non-GUI coverage.");
            testCase.verifyTrue(any(signatures == "gui/labkit_framework/ui|true"), ...
                "Fast changed UI validation should keep reusable UI GUI coverage.");
            testCase.verifyFalse(any(signatures == "gui/apps|true"), ...
                "Fast changed UI validation should avoid the full downstream app GUI suite.");
            testCase.verifyTrue(any(signatures == ...
                "gui/apps/image_measurement/image_enhance,gui/apps/image_measurement/batch_crop|true"), ...
                "Fast changed UI validation should run representative downstream app GUI coverage.");
            testCase.verifyTrue(any(contains(tests, "test_gui_layout_ui_declarative_app") & ...
                contains(tests, "controlled_interactions_suppress_programmatic_events") & ...
                contains(tests, "test_gui_layout_ui_debug_trace")), ...
                "Fast changed UI validation should use reusable UI test-name selectors.");
            testCase.verifyTrue(any(contains(tests, ...
                "controlled_region_selection_registers_transient_gesture")), ...
                "Fast changed UI validation should include a Runtime V2 gesture contract.");
            testCase.verifyTrue(all(strlength(reasons) > 0), ...
                "Changed validation plan steps should explain why each scope was selected.");

            appGuiSelectors = [ ...
                "image_enhance_workflow_applies_tool_and_exports", ...
                "batch_crop_workflow_exports_synthetic_crop"];
            testCase.verifyTrue(any(contains(tests, appGuiSelectors(1)) & ...
                contains(tests, appGuiSelectors(2))), ...
                "Fast changed UI validation should use test-name selectors to avoid the full reusable UI GUI suite.");
            verifySelectorsMatchTests(testCase, appGuiSelectors, ...
                ["gui/apps/image_measurement/image_enhance", ...
                "gui/apps/image_measurement/batch_crop"]);
            verifySelectorsMatchTests(testCase, [ ...
                "test_gui_layout_ui_declarative_app", ...
                "controlled_interactions_suppress_programmatic_events", ...
                "test_gui_layout_ui_debug_trace"], ...
                "gui/labkit_framework/ui");
            verifySelectorsMatchTests(testCase, ...
                "controlled_region_selection_registers_transient_gesture", ...
                "gui/labkit_framework/ui");
        end

        function changedValidationPlanRoutesLauncherToProjectGui(testCase)
            root = setupLabKitTestPath();

            steps = labkitValidationPlanForChangedPaths(root, "labkit_launcher.m");
            signatures = validationStepSignatures(steps);
            selectors = validationStepTestSelectors(steps);

            testCase.verifyTrue(any(signatures == "project|false"), ...
                "Launcher source changes should keep project guardrail coverage.");
            testCase.verifyTrue(any(signatures == "gui/project/launcher|true"), ...
                "Launcher source changes should run project launcher GUI coverage.");
            projectSelectors = selectors(signatures == "project|false");
            testCase.verifyTrue(any(contains(projectSelectors, "StartupBoundariesTest") & ...
                contains(projectSelectors, "PackageLabKitAppToolTest")), ...
                "Launcher project coverage should target its direct non-GUI contracts.");
        end

        function changedValidationPlanRoutesLauncherSupportByOwner(testCase)
            root = setupLabKitTestPath();

            steps = labkitValidationPlanForChangedPaths(root, [ ...
                "CHANGELOG.md"
                "docs/apps/README.md"
                "tools/deployment/packageLabKitApp.m"
                "tools/deployment/private/packageManifestText.m"
                "tests/shared/assertLauncherPackageCheckboxSelection.m"]);
            signatures = validationStepSignatures(steps);
            selectors = validationStepTestSelectors(steps);

            testCase.verifyTrue(any(signatures == "project/release|false"), ...
                "CHANGELOG changes should route to release guardrails instead of full headless.");
            testCase.verifyTrue(any(signatures == "project/docs|false"), ...
                "Human docs should route to documentation guardrails.");
            packageStep = signatures == "project|false";
            testCase.verifyTrue(any(contains(selectors(packageStep), ...
                "PackageLabKitAppToolTest")), ...
                "Deployment tools should route to package tool tests.");
            testCase.verifyTrue(any(signatures == "gui/project/launcher|true"), ...
                "Shared launcher helpers should route to launcher GUI tests.");
        end

        function changedValidationPlanRoutesProjectGuiTestsByOwner(testCase)
            root = setupLabKitTestPath();

            steps = labkitValidationPlanForChangedPaths(root, ...
                "tests/cases/gui/project/launcher/LauncherGuiTest.m");
            signatures = validationStepSignatures(steps);

            testCase.verifyEqual(signatures, "gui/project/launcher|true", ...
                "Project GUI test changes should rerun the owning project GUI suite.");
        end

        function changedValidationPlanTargetsChangedProjectTest(testCase)
            root = setupLabKitTestPath();

            steps = labkitValidationPlanForChangedPaths(root, ...
                "tests/cases/unit/project/PackageLabKitAppToolTest.m");
            signatures = validationStepSignatures(steps);
            selectors = validationStepTestSelectors(steps);

            testCase.verifyEqual(signatures, "project|false", ...
                "Project unit tests should remain in the project suite.");
            testCase.verifyEqual(selectors, "PackageLabKitAppToolTest", ...
                "A changed project unit test should rerun only its owning class.");
        end

        function changedValidationPlanRoutesFrameworkGuiTestsByOwner(testCase)
            root = setupLabKitTestPath();

            steps = labkitValidationPlanForChangedPaths(root, ...
                "tests/cases/gui/labkit_framework/ui/GuiLayoutUiRuntimeV2InteractionHubTest.m");
            signatures = validationStepSignatures(steps);

            testCase.verifyEqual(signatures, "gui/labkit_framework/ui|true", ...
                "LabKit framework GUI test changes should rerun the owning framework GUI suite.");
        end

        function changedValidationPlanTargetsSharedHelperConsumers(testCase)
            root = setupLabKitTestPath();

            guiSteps = labkitValidationPlanForChangedPaths(root, ...
                "tests/shared/guiTestHelpers.m");
            guiSignatures = validationStepSignatures(guiSteps);
            guiSelectors = split(validationStepTestSelectors(guiSteps), ",");
            testCase.verifyEqual(guiSignatures, "gui|true", ...
                "Shared GUI helpers should route to direct GUI consumers.");
            testCase.verifyGreaterThan(numel(guiSelectors), 1, ...
                "Shared GUI helper routing should retain multiple consumers.");
            testCase.verifyLessThan(numel(guiSelectors), ...
                officialGuiClassCount(root), ...
                "Shared GUI helper routing should avoid the full GUI suite.");
            testCase.verifyTrue(any(guiSelectors == "GuiLayoutDicPreprocessTest"), ...
                "Shared GUI helper routing should include real app consumers.");

            workflowSteps = labkitValidationPlanForChangedPaths(root, ...
                "tests/shared/labkitWorkflowDriver.m");
            workflowSelectors = split( ...
                validationStepTestSelectors(workflowSteps), ",");
            testCase.verifyLessThan(numel(workflowSelectors), ...
                numel(guiSelectors), ...
                "Workflow-driver changes should run only direct consumers.");
            testCase.verifyTrue(any(workflowSelectors == "GuiLayoutBatchCropTest"), ...
                "Workflow-driver routing should include app workflow consumers.");
        end

        function testCasePathsUseExplicitOwners(testCase)
            root = setupLabKitTestPath();
            caseFiles = trackedTestCaseFiles(root);
            blocked = caseFiles( ...
                contains(caseFiles, "/tests/cases/unit/labkit/") | ...
                contains(caseFiles, "/tests/cases/gui/labkit/") | ...
                contains(caseFiles, "/tests/cases/gui/gesture/"));

            testCase.verifyEmpty(blocked, ...
                "Test paths should use explicit owners: apps, labkit_framework, or project.");
        end

        function hiddenGuiTestsAvoidUiAutomationDriver(testCase)
            root = setupLabKitTestPath();
            files = trackedTestCaseFiles(root);
            files = files(contains(files, "/tests/cases/gui/"));
            offenders = strings(1, 0);
            for k = 1:numel(files)
                source = string(fileread(fullfile(root, extractAfter(files(k), 1))));
                if contains(source, "< matlab.uitest.TestCase")
                    offenders(end + 1) = files(k);
                end
            end
            testCase.verifyEmpty(offenders, ...
                ["Hidden GUI tests must use matlab.unittest.TestCase. " + ...
                "matlab.uitest.TestCase installs a display-only automation driver " + ...
                "that emits ViewReady callback errors for hidden figures. Findings: " + ...
                strjoin(offenders, ", ")]);
        end
    end
end

function signatures = validationStepSignatures(steps)
    signatures = strings(1, numel(steps));
    for k = 1:numel(steps)
        signatures(k) = strjoin(steps(k).Suites, ",") + "|" + ...
            string(steps(k).IncludeGui);
    end
end

function selectors = validationStepTestSelectors(steps)
    selectors = strings(1, numel(steps));
    for k = 1:numel(steps)
        if isfield(steps(k), "Tests")
            selectors(k) = strjoin(steps(k).Tests, ",");
        end
    end
end

function reasons = validationStepReasons(steps)
    reasons = strings(1, numel(steps));
    for k = 1:numel(steps)
        if isfield(steps(k), "Reason")
            reasons(k) = string(steps(k).Reason);
        end
    end
end

function verifySelectorsMatchTests(testCase, selectors, suites)
    output = listLabKitTestsQuietly( ...
        "Suites", suites, ...
        "Tests", selectors, ...
        "IncludeGui", true, ...
        "RunName", "selector_probe");
    testCase.verifyEqual(output.count, numel(selectors), ...
        "Fast representative test selectors should match current test names.");
end

function output = listLabKitTestsQuietly(varargin)
    evalc(['output = runLabKitTests(varargin{:}, "ListOnly", true, ' ...
        '"FailIfNoTests", false);']);
end

function files = trackedTestCaseFiles(root)
    command = sprintf('git -C "%s" ls-files --cached --others --exclude-standard "tests/cases"', root);
    [status, text] = system(command);
    assert(status == 0, 'Could not list tracked test case files.');
    files = string(strsplit(strtrim(text), newline));
    files = files(strlength(files) > 0 & endsWith(files, ".m"));
    exists = arrayfun(@(f) isfile(fullfile(root, f)), files);
    files = files(exists);
    files = "/" + replace(files, filesep, "/");
end

function count = officialGuiClassCount(root)
    entries = dir(fullfile(root, "tests", "cases", "gui", "**", "*.m"));
    count = numel(entries);
end
