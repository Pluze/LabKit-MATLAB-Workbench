classdef CscResultSpec < matlab.unittest.TestCase
    %CSCRESULTSPEC Specify all-cycle CSC export schema and failure rows.

    methods (Test, TestTags = {'Contract:result', 'Env:headless'})
        function exportsOneSchemaRowPerCycleAndEscapesCsv(testCase)
            [item, status] = labkit.dta.loadFile( ...
                dtaFixturePath("cv_cyclic_voltammetry_pt_reference.DTA"), "cvct");
            testCase.assertTrue(status.ok, status.message);
            choices = csc.analysisRun.analysisChoices();
            options = struct("mode", choices.modes(2), "area_cm2", "2");
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            destination = fullfile(folder, "csc.csv");

            rows = csc.resultFiles.buildResultsTable(item, options);
            csc.resultFiles.writeResultsCSV(item, destination, options);
            csv = string(fileread(destination));

            testCase.verifyEqual(height(rows), numel(item.curves));
            testCase.verifyEqual(rows.Properties.VariableNames(1:6), ...
                {'File', 'CurveIndex', 'CurveName', 'Rows', 'ScanRate_V_s', 'Area_cm2'});
            testCase.verifyEqual(rows.CurveIndex(:).', 1:numel(item.curves));
            testCase.verifyTrue(all(rows.Area_cm2 == 2));
            testCase.verifyTrue(all(rows.Status == "OK"));
            testCase.verifySubstring(csv, "File,CurveIndex,CurveName,Rows");
            testCase.verifySubstring(csv, ",2,");
        end

        function retainsOneFailureRowWhenNoCyclesAreAvailable(testCase)
            [item, status] = labkit.dta.loadFile( ...
                dtaFixturePath("cv_cyclic_voltammetry_pt_reference.DTA"), "cvct");
            testCase.assertTrue(status.ok, status.message);
            failed = item;
            failed.name = "failed.DTA";
            failed.curves = struct('name', {}, 'headers', {}, 'units', {}, ...
                'data', {}, 'numericMask', {});

            rows = csc.resultFiles.buildResultsTable(failed, struct("area_cm2", "2"));

            testCase.verifyEqual(height(rows), 1);
            testCase.verifyEqual(rows.CurveIndex, 0);
            testCase.verifyEqual(rows.Status, "No curve found");
        end
    end
end
