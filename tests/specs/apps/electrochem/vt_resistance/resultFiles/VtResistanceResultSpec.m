classdef VtResistanceResultSpec < matlab.unittest.TestCase
    %VTRESISTANCERESULTSPEC Specify VT resistance export schema and escaping.

    methods (Test, TestTags = {'Contract:result', 'Env:headless'})
        function preservesResultColumnsFailureRowsAndCsvEscaping(testCase)
            item = testfixtures.makeChronoFixtureItem('', 'chrono "vt".DTA');
            item.analysis = vt_resistance.analysisRun.computeResistance(item, struct());
            failed = struct("filepath", "failed.DTA", "name", 'failed "file".DTA', ...
                "meta", [], "tables", [], ...
                "analysis", struct("ok", false, "message", 'bad "msg"'));
            items = [item, failed];
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            destination = fullfile(folder, "results.csv");

            tableData = vt_resistance.resultFiles.buildResultsTable(items);
            vt_resistance.resultFiles.writeResultsCSV(items, destination);
            csv = string(fileread(destination));

            testCase.verifyEqual(string(tableData.Properties.VariableNames), [ ...
                "File", "Ic_A", "Ia_A", "Vc_ss_V", "Va_ss_V", "Vc_baseline_V", ...
                "Va_baseline_V", "dVc_V", "dVa_V", "Rc_bc_ohm", "Ra_bc_ohm", ...
                "Ravg_bc_ohm", "WindowMode", "Detection", "Status"]);
            testCase.verifyEqual(tableData.Ravg_bc_ohm(1), 100, "AbsTol", 1e-10);
            testCase.verifyTrue(isnan(tableData.Ravg_bc_ohm(2)));
            testCase.verifyEqual(tableData.Detection{2}, 'failed');
            testCase.verifySubstring(csv, '"chrono ""vt"".DTA"');
            testCase.verifySubstring(csv, '"failed ""file"".DTA"');
        end
    end
end
