classdef BatchCropProjectSpec < matlab.unittest.TestCase
    %BATCHCROPPROJECTSPEC Specify portable one-task-per-source migration.

    methods (Test, TestTags = {'Contract:persistence', 'Env:headless'})
        function migratesEmbeddedLegacyPixelsToDistinctPortableSources(testCase)
            spec = batch_crop.projectSpec();
            project = spec.Create();
            item = batch_crop.sourceFiles.emptyItem();
            item.path = "synthetic.png";
            item.image = uint8(reshape(1:120, 10, 12));
            project.inputs.items = [item; item];

            v2 = spec.Migrate(project, 1);
            migrated = spec.Migrate(v2, 2);

            testCase.verifyFalse(isfield(migrated.inputs.items, "image"));
            testCase.verifyFalse(isfield(migrated.inputs.items, "path"));
            testCase.verifyEqual(numel(migrated.inputs.sources), 2);
            testCase.verifyEqual(numel(unique(string({migrated.inputs.sources.id}))), 2);
            testCase.verifyTrue(spec.Validate(migrated));
        end
    end
end
