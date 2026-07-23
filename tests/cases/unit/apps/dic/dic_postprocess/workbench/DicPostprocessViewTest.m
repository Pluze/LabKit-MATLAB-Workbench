classdef DicPostprocessViewTest < matlab.unittest.TestCase
    %DICPOSTPROCESSVIEWTEST Verify GUI-free DIC postprocess view helpers.

    methods (Test, TestTags = {'Unit'})
        function tagFromPathPreservesLastMillimeterToken(testCase)
            setupLabKitTestPath();

            tag = dic_postprocess.resultFiles.tagFromPath( ...
                "run_0.5mm_repeat_1.25mm.mat");
            fallback = dic_postprocess.resultFiles.tagFromPath( ...
                "run_without_dimension.mat");

            testCase.verifyEqual(tag, "1.25mm");
            testCase.verifyEqual(fallback, "unknown_mm");
        end

        function summaryTableDataBuildsUiCellData(testCase)
            setupLabKitTestPath();

            metric = ["Mean"; "Std"];
            exx = [1.25; 0.5];
            eyy = [-2; 0.25];
            summary = table(metric, exx, eyy, ...
                'VariableNames', {'Metric', 'EXX', 'EYY'});

            data = dic_postprocess.overlayPreview.summaryTableData(summary);
            emptyData = dic_postprocess.overlayPreview.summaryTableData(table());

            testCase.verifyEqual(data, {'Mean', 1.25, -2; 'Std', 0.5, 0.25});
            testCase.verifyEqual(emptyData, {});
        end

        function definitionUsesCanonicalAppSdkStructure(testCase)
            setupLabKitTestPath();

            definition = dic_postprocess.definition();

            testCase.verifyClass(definition, "labkit.app.Definition");
            testCase.verifyClass(definition.ProjectSchema, ...
                "labkit.app.project.Schema");
        end
    end
end
