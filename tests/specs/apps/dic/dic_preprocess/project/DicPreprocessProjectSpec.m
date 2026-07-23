classdef DicPreprocessProjectSpec < matlab.unittest.TestCase
    %DICPREPROCESSPROJECTSPEC Specify durable DIC preprocess project schema.

    methods (Test, TestTags = {'Contract:persistence', 'Env:headless'})
        function createsAValidProjectWithoutDurableDecodedPixels(testCase)
            spec = dic_preprocess.projectSpec();
            project = spec.Create();
            project.inputs.sources = sourceRecord("referenceImage", "reference.png");

            testCase.verifyTrue(spec.Validate(project));
            testCase.verifyFalse(isfield(project.inputs, 'referenceImage'));
            testCase.verifyEmpty(spec.Migrate);
        end
    end
end

function source = sourceRecord(id, path)
[~, name, extension] = fileparts(path);
source = struct("id", id, "required", true, "role", "reference", ...
    "reference", struct("schemaVersion", 1, "relativePath", "", ...
    "originalPath", path, "fileName", string(name) + string(extension)));
end
