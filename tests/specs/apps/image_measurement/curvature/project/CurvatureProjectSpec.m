classdef CurvatureProjectSpec < matlab.unittest.TestCase
    %CURVATUREPROJECTSPEC Specify source-record migration and empty session state.

    methods (Test, TestTags = {'Contract:persistence', 'Env:headless'})
        function migratesTheOriginalSingleSourceFieldAndRebuildsAnEmptySession(testCase)
            definition = curvature.definition();
            project = definition.ProjectSchema.Create();
            session = definition.CreateSession(project, ...
                labkit.app.internal.runtime.CallbackContextFactory.disconnected());
            legacy = project;
            legacy.inputs.source = struct("absolutePath", "/tmp/image.png");
            legacy.inputs = rmfield(legacy.inputs, "sources");

            migrated = definition.ProjectSchema.Migrate(legacy, 1);

            testCase.verifyTrue(definition.ProjectSchema.Validate(project));
            testCase.verifyEqual(definition.ProjectSchema.Version, 2);
            testCase.verifyEmpty(session.cache.image);
            testCase.verifyEqual(session.workflow.editMode, "none");
            testCase.verifyEqual(migrated.inputs.sources, legacy.inputs.source);
            testCase.verifyFalse(isfield(migrated.inputs, "source"));
        end
    end
end
