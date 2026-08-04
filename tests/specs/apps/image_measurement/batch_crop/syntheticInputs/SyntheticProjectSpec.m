classdef SyntheticProjectSpec < matlab.unittest.TestCase
    % Regression: generated inputs satisfy the current Batch Crop project contract.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function provesSyntheticProject(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = batch_crop.definition();
            pack = labkittest.generateSyntheticInputs( ...
                definition, folder);

            testCase.verifyTrue(definition.ProjectSchema.Validate( ...
                pack.InitialProject));
            testCase.verifyEqual(exist(fullfile( ...
                folder, "synthetic-input-pack.json"), "file"), 2);
            centers = vertcat(pack.InitialProject.inputs.items.centerXY);
            testCase.verifyTrue(all(isfinite(centers), "all"));
        end
    end

    methods (Test, TestTags = {'Contract:source', 'Env:hidden-gui'})
        function startsTheSyntheticProjectWithoutControlLimitFailures(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = batch_crop.definition();
            pack = labkittest.generateSyntheticInputs( ...
                definition, folder);
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, pack.InitialProject, struct(), ...
                journal);
            cleanup = onCleanup(@() runtime.close());

            testCase.verifyTrue(isgraphics(runtime.figureHandle(), "figure"));
            testCase.verifyFalse(runtime.StartupFailed);
            roi = findall(runtime.figureHandle(), Type="rectangle");
            testCase.verifyNumElements(roi, 1);
            testCase.verifyEqual(string(roi.HitTest), "on");
            clear cleanup
        end
    end
end
