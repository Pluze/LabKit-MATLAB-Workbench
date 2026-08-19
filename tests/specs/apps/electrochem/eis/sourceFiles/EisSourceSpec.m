classdef EisSourceSpec < matlab.unittest.TestCase
    %EISSOURCESPEC Specify EIS canonical source fields and path filtering.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function loadsCanonicalZcurveItems(testCase)
            [item, status] = labkit.dta.loadFile( ...
                testfixtures.dtaFixturePath("eis_potentiostatic_zcurve.DTA"), "eis");
            testCase.assertTrue(status.ok, status.message);

            testCase.verifyEqual(string(item.type), "eis");
            testCase.verifyEqual(item.message, 'Using table: ZCURVE');
            testCase.verifyEqual(item.zcurve, item.curve);
            testCase.verifyEqual(numel(item.freq_Hz), item.n);
        end

        function acceptsOnlyEisDtaPaths(testCase)
            eisPath = testfixtures.dtaFixturePath( ...
                "eis_potentiostatic_zcurve.DTA");
            chrono = testfixtures.dtaFixturePath( ...
                "chrono_chronopot_current_pulse_0p2ms.DTA");

            accepted = eis.sourceFiles.matchesDtaKind([eisPath, chrono]);

            testCase.verifyEqual(accepted, [true false]);
        end
    end
end
