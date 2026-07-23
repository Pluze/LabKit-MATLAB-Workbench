classdef GaitProjectSpec < matlab.unittest.TestCase
    %GAITPROJECTSPEC Specify durable Gait project validation and migration.

    methods (Test, TestTags = {'Contract:persistence', 'Env:headless'})
        function requiresSourcesAndMigratesVersionOneOptionNames(testCase)
            spec = gait_analysis.projectSpec();
            project = spec.Create();
            project.inputs = rmfield(project.inputs, 'sources');
            testCase.verifyError(@() spec.Validate(project), "gait_analysis:InvalidProject");

            project = spec.Create();
            project.parameters = rmfield(project.parameters, { ...
                'minLiftOffIntervalSeconds', 'minSwingFrames', 'maxSwingFrames', ...
                'minStepLength', 'maxHipTranslation', 'detectionMinHeightSigma'});
            project.parameters.minStepIntervalSeconds = 0.25;
            project.parameters.minStepFrames = 4;
            project.parameters.maxStepFrames = 40;
            project.parameters.minStride = 3;
            project.parameters.maxBodyDrift = 9;

            migrated = spec.Migrate(project, 1);

            testCase.verifyEqual([migrated.parameters.minLiftOffIntervalSeconds, ...
                migrated.parameters.minSwingFrames, migrated.parameters.maxSwingFrames, ...
                migrated.parameters.minStepLength, migrated.parameters.maxHipTranslation], ...
                [0.25, 4, 40, 3, 9]);
            testCase.verifyFalse(isfield(migrated.parameters, 'minStride'));
        end
    end
end
