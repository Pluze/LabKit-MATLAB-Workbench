classdef GaitWorkflowSpec < matlab.unittest.TestCase
    %GAITWORKFLOWSPEC Specify Video Marker input, analysis, export, restore.

    methods (Test, TestTags = {'Contract:presentation', 'Env:hidden-gui'})
        function analyzesNavigatesExportsAndRestoresSyntheticPose(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            context = labkit.app.diagnostic.SampleContext(folder);
            pack = gait_analysis.debug.writeSamplePack(context);
            posePath = pack.InitialProject.inputs.sources(1).reference.originalPath;
            backend = struct( ...
                "chooseOutputFolder", @(~) labkit.app.dialog.Choice(folder), ...
                "alert", @(~, ~) []);
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                gait_analysis.definition(), [], backend);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            runtime.applyFileSelection("poseFile", posePath, 1);
            runtime.applyControlValue("originAtFirstFrameFirstPoint", true);
            runtime.invokeAction("runAnalysis");
            result = runtime.State.project.results.analysis;
            if height(result.stepTable) > 1
                runtime.applyTableSelection("stepTable", [2 1]);
                runtime.invokeAction("previousStep");
                runtime.invokeAction("nextStep");
            end
            runtime.invokeAction("chooseOutputFolder");
            runtime.invokeAction("exportResults");

            testCase.verifyTrue(runtime.State.session.cache.pose.ok);
            testCase.verifyTrue(result.ok);
            testCase.verifyGreaterThan(height(result.frameTable), 0);
            testCase.verifyGreaterThan(height(result.stepTable), 0);
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "gaitAxes.skeleton").Children);
            testCase.verifyNotEmpty(findall(figureValue, "Tag", "gaitAxes.angles").Children);
            [~, stem] = fileparts(posePath);
            testCase.verifyTrue(isfile(fullfile(folder, stem + "_summary.csv")));
            testCase.verifyTrue(isfile(fullfile(folder, stem + "_gait.labkit.json")));
            saved = fullfile(folder, "gait-project.mat");
            runtime.saveProject(runtime.State, saved);
            runtime.applyFileSelection("poseFile", strings(1, 0), zeros(1, 0));
            runtime.restoreProject(saved);
            testCase.verifyTrue(runtime.State.session.cache.pose.ok);
            testCase.verifyTrue(runtime.State.project.results.analysis.ok);
            clear cleanup
        end
    end
end
