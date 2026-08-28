classdef ImageSelectionSpec < matlab.unittest.TestCase
    % IMAGESELECTIONSPEC Regression: image navigation loads the selected source and restores its ROI layout selection.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function provesImageSelection(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            firstPath = fullfile(folder, "first.png");
            secondPath = fullfile(folder, "second.png");
            imwrite(uint8(ones(8, 10)), firstPath);
            imwrite(uint8(2 .* ones(8, 10)), secondPath);
            project = roi_analyzer.initialData();
            project.inputs.sources = [ ...
                labkit.app.source.record("image-1", "source-image", firstPath); ...
                labkit.app.source.record("image-2", "source-image", secondPath)];
            roi = roi_analyzer.roiLibrary.emptyRoi();
            roi.id = "roi-1";
            roi.templateId = project.annotations.templates(1).id;
            roi.centerXY = [5 4];
            project.annotations.items = struct( ...
                "sourceId", "image-2", "rois", roi);
            state = struct("project", project, ...
                "session", roi_analyzer.createSession(project, []));
            context = labkittest.createCallbackContext(struct( ...
                "log", @(varargin) [], "alert", @(varargin) []));

            state = roi_analyzer.sourceImages.next(state, context);
            testCase.verifyEqual(state.session.selection.sourceIndex, 2);
            testCase.verifyEqual(state.session.selection.sourceImages.Indices, 2);
            testCase.verifyEqual(state.session.cache.sourceId, "image-2");
            testCase.verifyEqual(state.session.selection.roiIndex, 1);
            state = roi_analyzer.sourceImages.previous(state, context);
            testCase.verifyEqual(state.session.selection.sourceIndex, 1);
            testCase.verifyEqual(state.session.cache.image, uint8(ones(8, 10)));
        end
    end
end
