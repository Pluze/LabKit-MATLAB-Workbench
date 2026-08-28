classdef SessionRebuildSpec < matlab.unittest.TestCase
    % SESSIONREBUILDSPEC Invariant: session reconstruction restores the first image while resetting transient transforms and clipboards.

    methods (Test, TestTags = {'Contract:state', 'Env:headless'})
        function provesSessionRebuild(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            imagePath = fullfile(folder, "source.png");
            imwrite(uint8(reshape(1:80, 8, 10)), imagePath);
            project = roi_analyzer.initialData();
            project.inputs.sources = labkit.app.source.record( ...
                "image-1", "source-image", imagePath);
            roi = roi_analyzer.roiLibrary.emptyRoi();
            roi.id = "roi-1";
            roi.templateId = project.annotations.templates(1).id;
            roi.centerXY = [5 4];
            project.annotations.items = struct( ...
                "sourceId", "image-1", "rois", roi);

            session = roi_analyzer.createSession(project, []);

            testCase.verifyEqual(session.selection.sourceIndex, 1);
            testCase.verifyEqual(session.selection.sourceImages.Indices, 1);
            testCase.verifyEqual(session.selection.roiIndex, 1);
            testCase.verifyEqual(session.selection.roiIndices, 1);
            testCase.verifyEqual(session.cache.sourceId, "image-1");
            testCase.verifyEqual(session.view, struct("shiftX", 0, "shiftY", 0));
            testCase.verifyEmpty(session.clipboard.rois);
            testCase.verifyEqual(session.clipboard.sourceId, "");
        end
    end
end
