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
    end
end
