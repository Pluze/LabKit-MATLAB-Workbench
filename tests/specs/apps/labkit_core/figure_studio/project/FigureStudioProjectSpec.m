classdef FigureStudioProjectSpec < matlab.unittest.TestCase
    %FIGURESTUDIOPROJECTSPEC Specify durable figure style migrations.

    methods (Test, TestTags = {'Contract:persistence', 'Env:headless'})
        function migratesTheVersionOneStyleWithoutLosingSavedBaseSize(testCase)
            spec = figure_studio.projectSpec();
            legacy = spec.Create();
            legacy.parameters.style = rmfield(legacy.parameters.style, ...
                {'annotationFontSize', 'legendFontSize', 'referenceLineWidth', ...
                 'xTickLabelAngle', 'referenceCanvasWidth', 'referenceCanvasHeight'});
            legacy.parameters.style.baseFontSize = 17;
            legacy.annotations.sourceDefaultStyle = legacy.parameters.style;

            migrated = spec.Migrate(legacy, 1);

            testCase.verifyEqual(migrated.parameters.style.baseFontSize, 17);
            testCase.verifyEqual(migrated.parameters.style.annotationFontSize, 54);
            testCase.verifyEqual(migrated.parameters.style.legendFontSize, 64);
            testCase.verifyEqual(migrated.parameters.style.xTickLabelAngle, "Horizontal");
            testCase.verifyTrue(spec.Validate(migrated));
        end

        function migratesTheVersionTwoAndThreeCanvasAndPanelFields(testCase)
            spec = figure_studio.projectSpec();
            versionTwo = spec.Create();
            versionTwo.parameters = rmfield(versionTwo.parameters, "canvasSize");
            versionTwo.parameters.aspectPreset = "Custom";
            versionTwo.annotations = rmfield(versionTwo.annotations, "limitOverrides");
            versionThree = spec.Create();
            versionThree.annotations = rmfield(versionThree.annotations, "panelIndex");

            migratedTwo = spec.Migrate(versionTwo, 2);
            migratedThree = spec.Migrate(versionThree, 3);

            testCase.verifyEqual(migratedTwo.parameters.aspectPreset, "Source");
            testCase.verifyEqual(migratedTwo.parameters.canvasSize, "Source size");
            testCase.verifyEqual(migratedTwo.annotations.limitOverrides, ...
                struct("xLim", [], "yLim", []));
            testCase.verifyEqual(migratedThree.annotations.panelIndex, 1);
            testCase.verifyError(@() spec.Migrate(spec.Create(), 0), ...
                "figure_studio:UnsupportedProjectVersion");
        end
    end
end
