classdef CscPresentationSpec < matlab.unittest.TestCase
    %CSCPRESENTATIONSPEC Specify compact CSC workbench data and readouts.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function projectsSelectedCycleMetricsIntoTheWorkbenchTable(testCase)
            [item, status] = labkit.dta.loadFile( ...
                testfixtures.dta.file("cv_cyclic_voltammetry_pt_reference.DTA"), "cvct");
            testCase.assertTrue(status.ok, status.message);
            choices = csc.analysisRun.analysisChoices();
            rows = csc.resultFiles.buildResultsTable(item, struct( ...
                "mode", choices.modes(2), "area_cm2", "2"));

            tableData = csc.analysisRun.cycleResultsTableData(rows, choices.modes(2));
            names = csc.analysisRun.cycleResultsColumnNames(choices.modes(2));

            testCase.verifySize(tableData, [height(rows), 6]);
            testCase.verifySubstring(string(tableData{1, 1}), ...
                string(rows.CurveIndex(1)) + ":");
            testCase.verifyEqual(tableData{1, 3}, rows.CSCcvCath_mCcm2(1), ...
                "AbsTol", 1e-13);
            testCase.verifySubstring(string(names{3}), "cathodic");
        end

        function presentsNormalizedAndChargeOnlyComparisonReadouts(testCase)
            choices = csc.analysisRun.analysisChoices();
            result = struct("ok", true, "Qct", 1.25e-4, "Qcv", 1.5e-4, ...
                "diff_C", -2.5e-5, "rel_pct", 18.1818181818, ...
                "dtErr", 3.25e-6, "area_cm2", 2);
            normalized = csc.analysisRun.comparisonReadout(result, choices.modes(2));
            result.area_cm2 = NaN;
            chargeOnly = csc.analysisRun.comparisonReadout(result, choices.modes(1));

            testCase.verifyTrue(normalized.ok);
            testCase.verifySubstring(string(normalized.qctText), "mC/cm^2");
            testCase.verifyEqual(string(normalized.statusText), "CSC normalized by 2 cm^2");
            testCase.verifyEqual(string(chargeOnly.statusText), "Charge shown (area not set)");
            testCase.verifyEqual(string(chargeOnly.qctText), ...
                string(sprintf("%.12e C", result.Qct)));
        end
    end
end
