classdef SyntheticInputSpec < matlab.unittest.TestCase
    % Regression: generated inputs satisfy the current Batch Crop project contract.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function provesSyntheticInput(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = batch_crop.definition();
            pack = labkittest.generateSyntheticInputs( ...
                definition, folder);

            testCase.verifyEqual(exist(fullfile( ...
                folder, "synthetic-input-pack.json"), "file"), 2);
            centers = vertcat(pack.InitialInput.inputs.items.centerXY);
            testCase.verifyTrue(all(isfinite(centers), "all"));
        end
    end

    methods (Test, TestTags = {'Contract:source', 'Env:hidden-gui'})
        function startsTheSyntheticInputWithoutControlLimitFailures(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = batch_crop.definition();
            pack = labkittest.generateSyntheticInputs( ...
                definition, folder);
            journal = labkittest.temporarySessionJournal(definition, folder);
            runtime = labkittest.createMatlabRuntime( ...
                definition, pack.InitialInput, struct(), ...
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
