classdef TestArchitectureSpec < matlab.unittest.TestCase
    %TESTARCHITECTURESPEC Specify one active owner/contract test architecture.

    methods (Test, TestTags = {'Contract:system', 'Env:headless'})
        function launcherDoesNotOwnFigureStudioOrDocumentationConsumers(testCase)
            root = labkittest.setup();
            controller = text(root, ...
                "+labkit/+app/+internal/+launcher/createLauncher.m");
            handoff = text(root, ...
                "+labkit/+app/+internal/+native/private/sendPlotsToStudio.m");
            documentation = text(root, ...
                "tools/docs/private/loadLabKitDocumentation.m");

            testCase.verifyFalse(any(contains(controller, ...
                ["labkit_FigureStudio_app" "labkitFigureStudioLauncher"])));
            testCase.verifyFalse(contains(handoff, ...
                "labkitFigureStudioLauncher"));
            testCase.verifySubstring(handoff, ...
                "labkit.app.internal.discovery.discoverApps");
            testCase.verifySubstring(documentation, ...
                "labkit.app.internal.launcher.appCatalog");
            testCase.verifyFalse(contains(documentation, ...
                "labkit_launcher("));
        end

        function catalogDescriptorsUseCurrentOwnerRoots(testCase)
            descriptors = labkittest.catalog();

            testCase.verifyNotEmpty(descriptors);
            testCase.verifyTrue(all(startsWith(string({descriptors.Owner}), ...
                ["apps/" "labkit/" "tools/" "tests/"]) | ...
                ismember(string({descriptors.Owner}), ...
                ["labkit_launcher" "repository"]) | ...
                string({descriptors.Owner}) == ""));
        end

        function mark10UsesExplicitBaseMatlabBackgroundRuntime(testCase)
            root = labkittest.setup();
            driver = text(root, "+labkit/+mark10/connect.m");
            testCase.verifySubstring(driver, ...
                "parfeval(backgroundPool, @mark10ServiceLoop");
            testCase.verifySubstring(driver, ...
                "parallel.pool.PollableDataQueue");
            testCase.verifyFalse(contains(driver, "parfeval(@"), ...
                "Background work must explicitly name backgroundPool.");
        end

        function defaultBuildRunsOneCompleteLocalGate(testCase)
            plan = buildfile;

            testCase.verifyEqual(plan.DefaultTasks, "changedFast");
            testCase.verifyEqual(sort(string(plan("changedFast").Dependencies)), ...
                ["codecheck", "docsCheck"]);
        end

    end
end

function value = text(root, relative)
value = string(fileread(fullfile(root, relative)));
end
