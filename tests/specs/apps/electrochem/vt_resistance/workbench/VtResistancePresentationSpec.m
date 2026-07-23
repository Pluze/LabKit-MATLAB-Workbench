classdef VtResistancePresentationSpec < matlab.unittest.TestCase
    %VTRESISTANCEPRESENTATIONSPEC Specify VT batch-table presentation values.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function summarizesSuccessfulAndFailedAnalysesForTheWorkbench(testCase)
            item = testfixtures.makeChronoFixtureItem();
            item.analysis = vt_resistance.analysisRun.computeResistance(item, struct());
            failed = item;
            failed.name = "failed.DTA";
            failed.analysis = struct("ok", false, "message", "bad");

            rows = vt_resistance.analysisRun.buildBatchTableData([item, failed]);

            testCase.verifySize(rows, [2, 9]);
            testCase.verifyEqual(rows{1, 1}, item.name);
            testCase.verifyEqual(rows{1, 8}, item.analysis.Ravg_abs_ohm, ...
                "AbsTol", 1e-12);
            testCase.verifyEqual(rows{1, 9}, item.analysis.detectMode);
            testCase.verifyTrue(isnan(rows{2, 2}));
            testCase.verifyEqual(rows{2, 9}, 'parse/analyze failed');
        end
    end
end
