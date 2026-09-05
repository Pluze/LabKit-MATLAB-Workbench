classdef ProjectArchiveSpec < matlab.unittest.TestCase
    % PROJECTARCHIVESPEC Regression: a saved project restores sources, selection, geometry, and results without partial state replacement.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function provesProjectArchive(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            imagePath = fullfile(folder, "source.png");
            archivePath = fullfile(folder, "project.mat");
            imwrite(uint16(reshape(1:120, 10, 12)), imagePath);
            project = roi_analyzer.initialData();
            project.inputs.sources = labkit.app.source.record( ...
                "image-1", "source-image", imagePath);
            roi = roi_analyzer.roiLibrary.emptyRoi();
            roi.id = "roi-1";
            roi.name = "Signal";
            roi.templateId = project.annotations.templates(1).id;
            roi.centerXY = [6 5];
            secondRoi = roi;
            secondRoi.id = "roi-2";
            secondRoi.name = "Reference";
            secondRoi.centerXY = [8 6];
            project.annotations.items = struct( ...
                "sourceId", "image-1", "rois", [roi; secondRoi]);
            project.results.items = struct( ...
                "sourceId", "image-1", "roiFingerprint", "measured", ...
                "summary", table(17, VariableNames="Mean"), ...
                "metrics", table());
            state = struct("project", project, ...
                "session", roi_analyzer.createSession(project, []));
            state.session.selection.roiIndex = 1;
            state.session.selection.roiIndices = [1 2];

            roi_analyzer.archive.writeFile(state, archivePath);
            restored = roi_analyzer.archive.readFile(archivePath, []);

            testCase.verifyEqual( ...
                string(restored.project.inputs.sources.path), string(imagePath));
            testCase.verifyEqual(restored.session.selection.sourceIndex, 1);
            testCase.verifyEqual(restored.session.selection.roiIndex, 1);
            testCase.verifyEqual(restored.session.selection.roiIndices, [1 2]);
            testCase.verifyEqual( ...
                vertcat(restored.project.annotations.items.rois.centerXY), ...
                [6 5; 8 6]);
            testCase.verifyEqual(restored.project.results.items.summary.Mean, 17);
            testCase.verifyFalse(isfield(restored.project.results, "batchStatus"));
            state.project.results.batchStatus = table("image-1", "Measured", ...
                VariableNames=["SourceId" "Status"]);
            roi_analyzer.archive.writeFile(state, archivePath);
            restored = roi_analyzer.archive.readFile(archivePath, []);
            testCase.verifyEqual(restored.project.results, state.project.results);
            invalidated = roi_analyzer.analysisRun.invalidate(restored.project.results, "image-1");
            testCase.verifyEmpty(invalidated.items.summary);
            testCase.verifyEmpty(invalidated.items.metrics);
            testCase.verifyEmpty(invalidated.batchStatus);
            invalidProject = state.project;
            invalidProject.results.batchStatus = struct("Status", "Measured");
            testCase.verifyError(@() roi_analyzer.archive.validateProject(invalidProject), ...
                "roi_analyzer:InvalidProject");
        end
    end
end
