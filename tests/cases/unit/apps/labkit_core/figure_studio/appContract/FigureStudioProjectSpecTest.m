classdef FigureStudioProjectSpecTest < matlab.unittest.TestCase
    %FIGURESTUDIOPROJECTSPECTEST Verify Figure Studio project requirements.

    methods (Test, TestTags = {'Unit'})
        function defaultProjectAcceptsAndRequiresSources(testCase)
            setupLabKitTestPath();
            spec = figure_studio.projectSpec();
            testCase.verifyEqual(spec.Version, 4);
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
                migrated.parameters.style.annotationFontSize, 54);
            testCase.verifyEqual( ...
                migrated.parameters.style.legendFontSize, 64);
            testCase.verifyEqual( ...
                migrated.parameters.style.referenceLineWidth, 4.0);
            testCase.verifyEqual( ...
                migrated.parameters.style.xTickLabelAngle, "Horizontal");
            testCase.verifyEqual( ...
                [migrated.parameters.style.referenceCanvasWidth ...
                migrated.parameters.style.referenceCanvasHeight], ...
                [legacy.parameters.style.canvasWidth ...
                legacy.parameters.style.canvasHeight]);
            testCase.verifyEqual(migrated.parameters.style.axesPosition, ...
                [0.185 0.17 0.795 0.78]);
            testCase.verifyTrue(accepts(spec, migrated));
        end

        function rejectsUnknownMigrationSource(testCase)
            setupLabKitTestPath();
            spec = figure_studio.projectSpec();
            testCase.verifyError(@() spec.Migrate(spec.Create(), 0), ...
                "figure_studio:UnsupportedProjectVersion");
        end

        function versionTwoCanvasControlsMigrateToFixedControlModel(testCase)
            setupLabKitTestPath();
            spec = figure_studio.projectSpec();
            legacy = spec.Create();
            legacy.parameters = rmfield(legacy.parameters, "canvasSize");
            legacy.parameters.aspectPreset = "Custom";
            legacy.annotations = rmfield(legacy.annotations, "limitOverrides");

            migrated = spec.Migrate(legacy, 2);

            testCase.verifyEqual(migrated.parameters.aspectPreset, "Source");
            testCase.verifyEqual(migrated.parameters.canvasSize, "Source size");
            testCase.verifyEqual(migrated.annotations.limitOverrides, ...
                struct("xLim", [], "yLim", []));
            testCase.verifyTrue(accepts(spec, migrated));
        end

        function versionThreeAddsSelectedPanel(testCase)
            setupLabKitTestPath();
            spec = figure_studio.projectSpec();
            legacy = spec.Create();
            legacy.annotations = rmfield(legacy.annotations, "panelIndex");

            migrated = spec.Migrate(legacy, 3);

            testCase.verifyEqual(migrated.annotations.panelIndex, 1);
            testCase.verifyTrue(accepts(spec, migrated));
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
