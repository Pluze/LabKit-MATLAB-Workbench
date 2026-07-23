classdef EisSourceSpec < matlab.unittest.TestCase
    %EISSOURCESPEC Specify EIS source-summary wording and canonical fields.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function summarizesCanonicalZcurveItems(testCase)
            [item, status] = labkit.dta.loadFile( ...
                testfixtures.dtaFixturePath("eis_potentiostatic_zcurve.DTA"), "eis");
            testCase.assertTrue(status.ok, status.message);

            summary = eis.sourceFiles.buildSummary(item);

            testCase.verifyEqual(string(item.type), "eis");
            testCase.verifyEqual(item.message, 'Using table: ZCURVE');
            testCase.verifyEqual(item.zcurve, item.curve);
            testCase.verifyEqual(numel(item.freq_Hz), item.n);
            testCase.verifySubstring(string(summary{2}), string(item.name));
            testCase.verifySubstring(string(summary{2}), "Freq");
            testCase.verifySubstring(string(summary{2}), "low->high/mixed");
        end
    end
end
