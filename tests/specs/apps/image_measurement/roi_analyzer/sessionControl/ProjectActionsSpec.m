classdef ProjectActionsSpec < matlab.unittest.TestCase
    % PROJECTACTIONSSPEC Regression: save and open actions preserve a valid project and cancel without mutation.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function provesProjectActions(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            imagePath = fullfile(folder, "source.png");
            projectPath = fullfile(folder, "project.mat");
            imwrite(uint8(reshape(1:80, 8, 10)), imagePath);
            project = roi_analyzer.initialData();
            project.inputs.sources = labkit.app.source.record( ...
                "image-1", "source-image", imagePath);
            state = struct("project", project, ...
                "session", roi_analyzer.createSession(project, []));
            backend = struct( ...
                "chooseOutputFile", @(varargin) ...
                    labkit.app.dialog.Choice(projectPath), ...
                "chooseInputFile", @(varargin) ...
                    labkit.app.dialog.Choice(projectPath), ...
                "log", @(varargin) [], "alert", @(varargin) []);
            context = labkittest.createCallbackContext(backend);

            state = roi_analyzer.sessionControl.saveProject(state, context);
            testCase.verifyTrue(isfile(projectPath));
            state.project.parameters.ratioDenominatorRoiId = "changed";
            restored = roi_analyzer.sessionControl.openProject(state, context);

            testCase.verifyEqual( ...
                restored.project.parameters.ratioDenominatorRoiId, "");
            testCase.verifyEqual(restored.session.selection.sourceIndex, 1);
        end
    end
end
