classdef CurvatureProjectSpec < matlab.unittest.TestCase
    %CURVATUREPROJECTSPEC Specify durable image-source migration.

    methods (Test, TestTags = {'Contract:persistence', 'Env:headless'})
        function migratesTheFormerSingularImageSource(testCase)
            spec = curvature.projectSpec();
            source = struct("absolutePath", "/tmp/image.png");
            project = spec.Create();
            project.inputs.source = source;
            project.inputs = rmfield(project.inputs, "sources");

            migrated = spec.Migrate(project, 1);

            testCase.verifyEqual(migrated.inputs.sources, source);
            testCase.verifyFalse(isfield(migrated.inputs, "source"));
            testCase.verifyTrue(spec.Validate(migrated));
        end
    end
end
