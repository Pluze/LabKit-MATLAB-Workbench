classdef FigureStudioProjectSpecTest < matlab.unittest.TestCase
    %FIGURESTUDIOPROJECTSPECTEST Verify Figure Studio project requirements.

    methods (Test, TestTags = {'Unit'})
        function defaultProjectAcceptsAndRequiresSources(testCase)
            setupLabKitTestPath();
            spec = figure_studio.projectSpec();
            testCase.verifyEqual(spec.Version, 2);
            testCase.verifyClass(spec.Migrate, "function_handle");
            project = spec.Create();
            testCase.verifyTrue(accepts(spec, project));
            project.inputs = rmfield(project.inputs, 'sources');
            testCase.verifyFalse(accepts(spec, project));
        end

        function versionOneStyleMigratesWithoutLosingSavedValues(testCase)
            setupLabKitTestPath();
            spec = figure_studio.projectSpec();
            legacy = spec.Create();
            legacy.parameters.style = rmfield( ...
                legacy.parameters.style, ...
                {'annotationFontSize', 'legendFontSize', ...
                'referenceLineWidth', 'xTickLabelAngle', ...
                'referenceCanvasWidth', 'referenceCanvasHeight'});
            legacy.parameters.style.baseFontSize = 17;
            legacy.annotations.sourceDefaultStyle = ...
                legacy.parameters.style;

            migrated = spec.Migrate(legacy, 1);

            testCase.verifyEqual( ...
                migrated.parameters.style.baseFontSize, 17);
            testCase.verifyEqual( ...
                migrated.parameters.style.annotationFontSize, 20);
            testCase.verifyEqual( ...
                migrated.parameters.style.legendFontSize, 15);
            testCase.verifyEqual( ...
                migrated.parameters.style.referenceLineWidth, 1.2);
            testCase.verifyEqual( ...
                migrated.parameters.style.xTickLabelAngle, "Horizontal");
            testCase.verifyEqual( ...
                [migrated.parameters.style.referenceCanvasWidth ...
                migrated.parameters.style.referenceCanvasHeight], ...
                [legacy.parameters.style.canvasWidth ...
                legacy.parameters.style.canvasHeight]);
            testCase.verifyTrue(accepts(spec, migrated));
        end

        function rejectsUnknownMigrationSource(testCase)
            setupLabKitTestPath();
            spec = figure_studio.projectSpec();
            testCase.verifyError(@() spec.Migrate(spec.Create(), 0), ...
                "figure_studio:UnsupportedProjectVersion");
        end
    end
end

function accepted = accepts(spec, project)
    try
        accepted = spec.Validate(project);
        accepted = islogical(accepted) && isscalar(accepted) && accepted;
    catch
        accepted = false;
    end
end
