classdef DicPostprocessViewTest < matlab.unittest.TestCase
    %DICPOSTPROCESSVIEWTEST Verify GUI-free DIC postprocess view helpers.

    methods (Test, TestTags = {'Unit'})
        function displayPathReportsLoadedAndMissingPaths(testCase)
            setupLabKitTestPath();

            testCase.verifyEqual(dic_postprocess.view.displayPath(""), 'none');
            testCase.verifyEqual(dic_postprocess.view.displayPath("sample.mat"), 'sample.mat');
        end

        function tagFromPathPreservesLastMillimeterToken(testCase)
            setupLabKitTestPath();

            tag = dic_postprocess.view.tagFromPath("run_0.5mm_repeat_1.25mm.mat");
            fallback = dic_postprocess.view.tagFromPath("run_without_dimension.mat");

            testCase.verifyEqual(tag, '1.25mm');
            testCase.verifyEqual(fallback, 'unknown_mm');
        end

        function summaryTableDataBuildsUiCellData(testCase)
            setupLabKitTestPath();

            metric = ["Mean"; "Std"];
            exx = [1.25; 0.5];
            eyy = [-2; 0.25];
            summary = table(metric, exx, eyy, ...
                'VariableNames', {'Metric', 'EXX', 'EYY'});

            data = dic_postprocess.view.summaryTableData(summary);
            emptyData = dic_postprocess.view.summaryTableData(table());

            testCase.verifyEqual(data, {'Mean', 1.25, -2; 'Std', 0.5, 0.25});
            testCase.verifyEqual(emptyData, {});
        end

        function colorbarLevelsTableMatchesColormapAndRange(testCase)
            setupLabKitTestPath();

            opts = struct();
            opts.colorRange = [-0.2 0.4];
            opts.colormap = [1 0 0; 0 1 0; 0 0 1];

            T = dic_postprocess.view.colorbarLevelsTable(opts);

            testCase.verifyEqual(T.StrainLevel, [-0.2; 0.1; 0.4], 'AbsTol', 1e-12);
            testCase.verifyEqual(T.Red, [1; 0; 0]);
            testCase.verifyEqual(T.Green, [0; 1; 0]);
            testCase.verifyEqual(T.Blue, [0; 0; 1]);
        end
    end
end
