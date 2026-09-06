classdef EisResultSpec < matlab.unittest.TestCase
    %EISRESULTSPEC Specify EIS axis/file-named export tables.

    methods (Test, TestTags = {'Contract:result', 'Env:headless'})
        function preservesEveryTraceWhenExportNamesCollide(testCase)
            item = EisResultSpec.canonicalItem(testCase);
            items = repmat(item, 1, 4);
            names = ["trace-a.DTA", "trace/a.DTA", "trace-a.DTA", ...
                string(repmat('x', 1, namelengthmax))];
            axes = eis.overlayPlot.axisItems();
            units = eis.impedanceDisplay.catalog();
            for index = 1:numel(items)
                items(index).name = char(names(index));
                items(index).Zreal_ohm(:) = index * 1000;
                items(index).Zimag_ohm(:) = -index * 2000;
                items(index).negZimag_ohm(:) = index * 2000;
            end
            actual = eis.resultFiles.buildExportTable(items, ...
                axes(5), axes(7), units.choices(3), false, false);
            testCase.assertEqual(width(actual), 1 + 2 * numel(items));
            for index = 1:numel(items)
                testCase.verifyEqual(actual{:, 2 * index}, ...
                    repmat(index, item.n, 1));
                testCase.verifyEqual(actual{:, 2 * index + 1}, ...
                    repmat(2 * index, item.n, 1));
            end
            testCase.verifyEqual(actual, eis.resultFiles.buildExportTable( ...
                items, axes(5), axes(7), units.choices(3), false, false));
        end

        function buildsStableAxisAndFileNamedExportColumns(testCase)
            item = EisResultSpec.canonicalItem(testCase);
            axes = eis.overlayPlot.axisItems();
            units = eis.impedanceDisplay.catalog();

            tableData = eis.resultFiles.buildExportTable(item, ...
                axes(5), axes(7), units.choices(3), false, false);

            expectedX = matlab.lang.makeValidName(sprintf("X_%s_%s", ...
                "zreal_kohm", matlab.lang.makeValidName(item.name)));
            expectedY = matlab.lang.makeValidName(sprintf("Y_%s_%s", ...
                "zimag_kohm", matlab.lang.makeValidName(item.name)));
            testCase.verifyEqual(tableData.Properties.VariableNames(1), {'RowIndex'});
            testCase.verifyTrue(ismember(expectedX, tableData.Properties.VariableNames));
            testCase.verifyTrue(ismember(expectedY, tableData.Properties.VariableNames));
            testCase.verifyEqual(height(tableData), item.n);
            testCase.verifyEqual(tableData.(expectedX), ...
                item.Zreal_ohm / 1e3, "AbsTol", 1e-12);
        end
    end

    methods (Static, Access = private)
        function item = canonicalItem(testCase)
            [item, status] = labkit.dta.loadFile( ...
                testfixtures.dta.file("eis_potentiostatic_zcurve.DTA"), "eis");
            testCase.assertTrue(status.ok, status.message);
        end
    end
end
