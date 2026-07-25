classdef SyntheticProjectSpec < matlab.unittest.TestCase
    % SYNTHETICPROJECTSPEC Regression: synthetic debug samples must satisfy the current Batch Crop project contract.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function provesSyntheticProject(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = batch_crop.definition();
            pack = definition.BuildDebugSample( ...
                labkit.app.diagnostic.SampleContext(folder));
            diagnostics = labkit.app.diagnostic.Options( ...
                ArtifactFolder=folder, Sample="synthetic");

            runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
                definition, [], struct(), diagnostics);

            testCase.verifyClass(runtime, "labkit.app.internal.RuntimeKernel");
            testCase.verifyEqual(exist(fullfile(folder, "sample-pack.json"), "file"), 2);
            centers = vertcat(pack.InitialProject.inputs.items.centerXY);
            testCase.verifyTrue(all(isfinite(centers), "all"));
        end
    end

    methods (Test, TestTags = {'Contract:source', 'Env:hidden-gui'})
        function startsTheSyntheticProjectWithoutControlLimitFailures(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            definition = batch_crop.definition();
            pack = definition.BuildDebugSample( ...
                labkit.app.diagnostic.SampleContext(folder));

            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                definition, pack.InitialProject, struct());
            cleanup = onCleanup(@() runtime.close());

            testCase.verifyTrue(isgraphics(runtime.figureHandle(), "figure"));
            testCase.verifyFalse(runtime.StartupFailed);
            clear cleanup
        end
    end
end
