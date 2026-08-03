classdef VtResistanceSourceSpec < matlab.unittest.TestCase
    %VTRESISTANCESOURCESPEC Guard resistance project-source reconstruction.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function emptySourcesReturnTheDeclaredStructVector(testCase)
            project = vt_resistance.projectSpec().Create();

            items = vt_resistance.sourceFiles.loadProjectItems( ...
                strings(0, 1), project.parameters);

            testCase.verifyClass(items, "struct");
            testCase.verifySize(items, [0 0]);
        end

        function acceptsOnlyChronoDtaPaths(testCase)
            chrono = testfixtures.dtaFixturePath( ...
                "chrono_chronopot_current_pulse_0p2ms.DTA");
            eisPath = testfixtures.dtaFixturePath( ...
                "eis_potentiostatic_zcurve.DTA");

            accepted = vt_resistance.sourceFiles.matchesDtaKind( ...
                [chrono, eisPath]);

            testCase.verifyEqual(accepted, [true false]);
        end
    end
end
