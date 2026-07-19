classdef GuiLayoutGaitAnalysisTest < matlab.unittest.TestCase
    % Verify Gait Analysis through the explicit App SDK runtime.
    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function nativeLayoutUsesSemanticTargets(testCase)
            setupLabKitTestPath();
            helpers = guiTestHelpers();
            helpers.assertUifigureAvailable();
            cleanup = onCleanup(@() helpers.closeAllFigures());
            figure = labkit_GaitAnalysis_app();

            ids = ["poseFile", "runAnalysis", "summaryTable", ...
                "stepTable", "chooseOutputFolder", "exportResults", ...
                "gaitAxes.skeleton", "gaitAxes.angles", ...
                "gaitAxes.segments"];
            for id = ids
                testCase.verifyEqual(numel(findall( ...
                    figure, "Tag", id)), 1);
            end
            clear cleanup
        end

        function poseDrivesAnalysisNavigationExportAndRestore(testCase)
            setupLabKitTestPath();
            helpers = guiTestHelpers();
            helpers.assertUifigureAvailable();
            outputFolder = string(tempname);
            mkdir(outputFolder);
            folderCleanup = onCleanup(@() removeTempFolder(outputFolder));
            backend = struct( ...
                "chooseOutputFolder", @(~) ...
                    labkit.app.dialog.Choice(outputFolder), ...
                "alert", @(~, ~) []);
            app = gait_analysis.definition();
            runtime = app.createMatlabRuntime([], backend);
            runtimeCleanup = onCleanup(@() runtime.close());
            figure = runtime.figureHandle();
            pack = gait_analysis.debug.writeSamplePack();

            runtime.applyFileSelection( ...
                "poseFile", pack.representativeFiles, 1);

            testCase.verifyTrue(runtime.State.session.cache.pose.ok);
            testCase.verifyEqual( ...
                runtime.State.project.parameters.frameRate, 30);
            skeleton = findall(figure, "Tag", "gaitAxes.skeleton");
            testCase.verifyNotEmpty(skeleton.Children);
            testCase.verifyEqual(skeleton.YDir, 'reverse');

            runtime.invokeAction("runAnalysis");

            result = runtime.State.project.results.analysis;
            testCase.verifyTrue(result.ok);
            testCase.verifyGreaterThan(height(result.frameTable), 0);
            testCase.verifyGreaterThan(height(result.stepTable), 0);
            angles = findall(figure, "Tag", "gaitAxes.angles");
            testCase.verifyNotEmpty(angles.Children);
            testCase.verifyEqual(angles.YDir, 'normal');
            if height(result.stepTable) > 1
                runtime.applyTableSelection("stepTable", [2 1]);
                testCase.verifyEqual( ...
                    runtime.State.session.selection.currentStepIndex, 2);
                runtime.invokeAction("previousStep");
                testCase.verifyEqual( ...
                    runtime.State.session.selection.currentStepIndex, 1);
                runtime.invokeAction("nextStep");
                testCase.verifyEqual( ...
                    runtime.State.session.selection.currentStepIndex, 2);
            end

            runtime.invokeAction("chooseOutputFolder");
            runtime.invokeAction("exportResults");
            expected = ["synthetic_video_marker_autosave_frames.csv", ...
                "synthetic_video_marker_autosave_coordinates.csv", ...
                "synthetic_video_marker_autosave_steps.csv", ...
                "synthetic_video_marker_autosave_summary.csv", ...
                "synthetic.video_marker.autosave_gait.labkit.json"];
            for filepath = fullfile(outputFolder, expected)
                testCase.verifyTrue(isfile(filepath), ...
                    "Missing gait output: " + filepath);
            end

            projectPath = fullfile(outputFolder, "gait-project.mat");
            runtime.saveProject(runtime.State, projectPath);
            runtime.applyFileSelection( ...
                "poseFile", strings(1, 0), zeros(1, 0));
            testCase.verifyFalse(runtime.State.session.cache.pose.ok);
            runtime.restoreProject(projectPath);
            testCase.verifyTrue(runtime.State.session.cache.pose.ok);
            testCase.verifyTrue( ...
                runtime.State.project.results.analysis.ok);
            clear runtimeCleanup folderCleanup
        end
    end
end

function removeTempFolder(folder)
if exist(folder, "dir") == 7
    rmdir(folder, "s");
end
end
