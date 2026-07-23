classdef EisResultSpec < matlab.unittest.TestCase
    %EISRESULTSPEC Specify EIS axis/file-named export tables.

    methods (Test, TestTags = {'Contract:result', 'Env:headless'})
        function buildsStableAxisAndFileNamedExportColumns(testCase)
            item = EisResultSpec.canonicalItem(testCase);
            axes = eis.overlayPlot.axisItems();

            tableData = eis.resultFiles.buildExportTable(item, ...
                axes(5), axes(7), false, false);

            expectedX = matlab.lang.makeValidName(sprintf("X_%s_%s", ...
                "zreal_ohm", matlab.lang.makeValidName(item.name)));
            expectedY = matlab.lang.makeValidName(sprintf("Y_%s_%s", ...
                "zimag_ohm", matlab.lang.makeValidName(item.name)));
            testCase.verifyEqual(tableData.Properties.VariableNames(1), {'RowIndex'});
            testCase.verifyTrue(ismember(expectedX, tableData.Properties.VariableNames));
            testCase.verifyTrue(ismember(expectedY, tableData.Properties.VariableNames));
            testCase.verifyEqual(height(tableData), item.n);
        end
    end

    methods (Static, Access = private)
        function item = canonicalItem(testCase)
            [item, status] = labkit.dta.loadFile( ...
                testfixtures.dtaFixturePath("eis_potentiostatic_zcurve.DTA"), "eis");
            testCase.assertTrue(status.ok, status.message);
        end
    end
end
