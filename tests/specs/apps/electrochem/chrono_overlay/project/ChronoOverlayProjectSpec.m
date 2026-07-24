classdef ChronoOverlayProjectSpec < matlab.unittest.TestCase
    %CHRONOOVERLAYPROJECTSPEC Specify durable Chrono Overlay project migration.

    methods (Test, TestTags = {'Contract:persistence', 'Env:headless'})
        function preservesDefinitionMetadataAndRemovesDecodedLegacyItems(testCase)
            definition = chrono_overlay.definition();
            project = definition.ProjectSchema.Create();
            item = struct("name", "synthetic.DTA", "tAligned_s", [-1; 0; 1], ...
                "Vf_V", [10; 20; 30], "Im_A", [1; 2; 3]);
            legacy = project;
            legacy.inputs.items = item;

            migrated = definition.ProjectSchema.Migrate(legacy, 1);
            version = labkit_ChronoOverlay_app("version");
            invalid = project;
            invalid.parameters.lineWidth = Inf;

            testCase.verifyTrue(definition.ProjectSchema.Validate(project));
            testCase.verifyEqual(definition.ProjectSchema.Version, 2);
            testCase.verifyFalse(isfield(migrated.inputs, "items"));
            testCase.verifyFalse(definition.ProjectSchema.Validate(invalid));
            testCase.verifyEqual(string(version.version), definition.AppVersion);
            testCase.verifyError(@() definition.ProjectSchema.Migrate(project, 0), ...
                "chrono_overlay:UnsupportedProjectVersion");
        end
    end
end
