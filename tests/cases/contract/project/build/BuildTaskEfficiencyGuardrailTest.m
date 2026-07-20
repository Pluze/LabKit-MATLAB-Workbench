classdef BuildTaskEfficiencyGuardrailTest < matlab.unittest.TestCase
    %BUILDTASKEFFICIENCYGUARDRAILTEST Guardrails for fast validation routing.

    methods (Test, TestTags = {'Integration', 'Style'})
        function broadBuildTasksUseTheOfficialSingleProcessRunner(testCase)
            root = setupLabKitTestPath();
            source = string(fileread(fullfile(root, "buildfile.m")));

            testCase.verifyTrue(contains(source, ...
                "runBuildTests(spec.Name, args{:})"));
            testCase.verifyFalse(contains(source, ...
                "labkitRunInternalShards"), ...
                ["Measured worker orchestration did not reduce end-to-end " ...
                "runtime and should not return without new evidence."]);
        end

        function changedFastValidationPlanUsesRepresentativeAppGuiCoverage(testCase)
            root = setupLabKitTestPath();

            steps = labkitValidationPlanForChangedPaths(root, ...
                "+labkit/+app/+internal/@MatlabPlatformAdapter/MatlabPlatformAdapter.m", ...
                "Mode", "fast");
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
            testCase.verifyTrue(any(contains(tests, ...
                "reconcilesChronoLikeSemanticTree") & ...
                contains(tests, "nativeCallbacksUseTypedRuntimeEntrypoints") & ...
                contains(tests, "replacesChoicesWhenCurrentValueDisappears")), ...
                "Fast changed UI validation should use reusable UI test-name selectors.");
            testCase.verifyTrue(any(contains(tests, ...
                "reconcilesManagedRectangleAndDispatchesDirectCallback")), ...
                "Fast changed UI validation should include a managed gesture contract.");
            testCase.verifyTrue(all(strlength(reasons) > 0), ...
                "Changed validation plan steps should explain why each scope was selected.");

            appGuiSelectors = [ ...
                "image_enhance_workflow_applies_tool_and_exports", ...
                "cropTasksCenterAndExportSyntheticImages"];
            testCase.verifyTrue(any(contains(tests, appGuiSelectors(1)) & ...
                contains(tests, appGuiSelectors(2))), ...
                "Fast changed UI validation should use test-name selectors to avoid the full reusable UI GUI suite.");
            verifySelectorsMatchTests(testCase, appGuiSelectors, ...
                ["gui/apps/image_measurement/image_enhance", ...
                "gui/apps/image_measurement/batch_crop"]);
            verifySelectorsMatchTests(testCase, [ ...
                "reconcilesChronoLikeSemanticTree", ...
                "nativeCallbacksUseTypedRuntimeEntrypoints", ...
                "replacesChoicesWhenCurrentValueDisappears"], ...
                "gui/labkit_framework/ui");
            verifySelectorsMatchTests(testCase, ...
                "reconcilesManagedRectangleAndDispatchesDirectCallback", ...
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
                "docs/history/records/2026/07/LK-20260716-runtime-identity-contracts.md"
                "docs/apps/README.md"
                "tools/deployment/packageLabKitApp.m"
                "tools/deployment/private/packageManifestText.m"
                "tests/shared/assertLauncherPackageCheckboxSelection.m"]);
            signatures = validationStepSignatures(steps);
            selectors = validationStepTestSelectors(steps);

            testCase.verifyTrue(any(signatures == "project/docs|false"), ...
                "Human docs and component history should route to documentation guardrails.");
            packageStep = signatures == "project|false";
            testCase.verifyTrue(any(contains(selectors(packageStep), ...
                "PackageLabKitAppToolTest")), ...
                "Deployment tools should route to package tool tests.");
            testCase.verifyTrue(any(signatures == "gui/project/launcher|true"), ...
                "Shared launcher helpers should route to launcher GUI tests.");
        end

        function changedAppSourceRoutesIsolatedPathContract(testCase)
            root = setupLabKitTestPath();

            steps = labkitValidationPlanForChangedPaths(root, ...
                "apps/gait/gait_analysis/+gait_analysis/definition.m");
            signatures = validationStepSignatures(steps);
            selectors = validationStepTestSelectors(steps);

            isolated = signatures == "contract/apps|false";
            testCase.verifyTrue(any(isolated), ...
                "App source changes should run the App isolation contract.");
            testCase.verifyTrue(any(contains(selectors(isolated), ...
                "publicAppsLoadContractsAndDebugSamplesOnOwningPath")), ...
                "The changed-file plan should name the focused isolation test.");
            verifySelectorsMatchTests(testCase, ...
                "publicAppsLoadContractsAndDebugSamplesOnOwningPath", ...
                "contract/apps");
        end

        function changedValidationPlanRoutesProjectGuiTestsByOwner(testCase)
            root = setupLabKitTestPath();

            steps = labkitValidationPlanForChangedPaths(root, ...
                "tests/cases/gui/project/launcher/LauncherGuiTest.m");
            signatures = validationStepSignatures(steps);

            testCase.verifyEqual(signatures, "|true");
            testCase.verifyEqual(validationStepFileSelectors(steps), ...
                "tests/cases/gui/project/launcher/LauncherGuiTest.m", ...
                "A changed project GUI test should rerun exactly itself.");
        end

        function changedValidationPlanTargetsChangedProjectTest(testCase)
            root = setupLabKitTestPath();

            steps = labkitValidationPlanForChangedPaths(root, ...
                "tests/cases/unit/project/PackageLabKitAppToolTest.m");
            signatures = validationStepSignatures(steps);

            testCase.verifyEqual(signatures, "|false");
            testCase.verifyEqual(validationStepFileSelectors(steps), ...
                "tests/cases/unit/project/PackageLabKitAppToolTest.m", ...
                "A changed project unit test should rerun exactly itself.");
        end

        function changedValidationPlanRoutesFrameworkGuiTestsByOwner(testCase)
            root = setupLabKitTestPath();

            steps = labkitValidationPlanForChangedPaths(root, ...
                "tests/cases/gui/labkit_framework/ui/UiMatlabPlatformAdapterTest.m");
            signatures = validationStepSignatures(steps);

            testCase.verifyEqual(signatures, "|true");
            testCase.verifyEqual(validationStepFileSelectors(steps), ...
                "tests/cases/gui/labkit_framework/ui/UiMatlabPlatformAdapterTest.m", ...
                "A changed framework GUI test should rerun exactly itself.");
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

function selectors = validationStepFileSelectors(steps)
    selectors = strings(1, numel(steps));
    for k = 1:numel(steps)
        if isfield(steps(k), "Files")
            selectors(k) = strjoin(steps(k).Files, ",");
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
