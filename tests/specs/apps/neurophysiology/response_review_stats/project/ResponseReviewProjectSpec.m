classdef ResponseReviewProjectSpec < matlab.unittest.TestCase
    %RESPONSEREVIEWPROJECTSPEC Specify source-collection project migration.

    methods (Test, TestTags = {'Contract:persistence', 'Env:headless'})
        function migratesTheFormerSingularSourceToTheCanonicalCollection(testCase)
            spec = response_review_stats.projectSpec();
            source = struct("absolutePath", "/tmp/responses.csv");
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
