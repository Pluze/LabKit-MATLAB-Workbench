classdef CicSourceSpec < matlab.unittest.TestCase
    %CICSOURCESPEC Guard CIC project-source reconstruction.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function emptySourcesReturnTheDeclaredStructVector(testCase)
            project = cic.initialData();

            items = cic.sourceFiles.loadProjectItems( ...
                strings(0, 1), project.parameters);

            testCase.verifyClass(items, "struct");
            testCase.verifySize(items, [0 0]);
        end

        function acceptsOnlyChronoDtaPaths(testCase)
            chrono = testfixtures.dtaFixturePath( ...
                "chrono_chronopot_current_pulse_0p2ms.DTA");
            eisPath = testfixtures.dtaFixturePath( ...
                "eis_potentiostatic_zcurve.DTA");

            accepted = cic.sourceFiles.matchesDtaKind([chrono, eisPath]);

            testCase.verifyEqual(accepted, [true false]);
        end
    end
end
