classdef SyntheticProjectSpec < matlab.unittest.TestCase
    % SYNTHETICPROJECTSPEC Regression: synthetic debug samples must satisfy the current Batch Crop project contract.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function provesSyntheticProject(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            diagnostics = labkit.app.diagnostic.Options( ...
                ArtifactFolder=folder, Sample="synthetic");

            runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
                batch_crop.definition(), [], struct(), diagnostics);

            testCase.verifyClass(runtime, "labkit.app.internal.RuntimeKernel");
            testCase.verifyEqual(exist(fullfile(folder, "sample-pack.json"), "file"), 2);
        end
    end
end
