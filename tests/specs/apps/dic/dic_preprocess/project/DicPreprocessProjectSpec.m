classdef DicPreprocessProjectSpec < matlab.unittest.TestCase
    %DICPREPROCESSPROJECTSPEC Specify durable DIC preprocess project schema.

    methods (Test, TestTags = {'Contract:persistence', 'Env:headless'})
        function createsAValidProjectAndMigratesTheRedundantPreview(testCase)
            spec = dic_preprocess.projectSpec();
            project = spec.Create();
            project.inputs.sources = sourceRecord("referenceImage", "reference.png");
            legacy = project;
            legacy.parameters.previewMode = "Current moving image";
            migrated = spec.Migrate(legacy, 1);

            testCase.verifyTrue(spec.Validate(project));
            testCase.verifyTrue(spec.Validate(migrated));
            testCase.verifyEqual(migrated.parameters.previewMode, "Current pair");
            testCase.verifyFalse(isfield(project.inputs, 'referenceImage'));
            testCase.verifyError(@() spec.Migrate(project, 0), ...
                "dic_preprocess:UnsupportedProjectMigration");
        end
    end
end

function source = sourceRecord(id, path)
[~, name, extension] = fileparts(path);
source = struct("id", id, "required", true, "role", "reference", ...
    "reference", struct("schemaVersion", 1, "relativePath", "", ...
    "originalPath", path, "fileName", string(name) + string(extension)));
end
