classdef CscSourceSpec < matlab.unittest.TestCase
    %CSCSOURCESPEC Guard CSC project-source reconstruction.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function emptySourcesReturnTheDeclaredStructVector(testCase)
            items = csc.sourceFiles.loadProjectItems(strings(0, 1));

            testCase.verifyClass(items, "struct");
            testCase.verifySize(items, [0 0]);
        end

        function acceptsOnlyCvCtDtaPaths(testCase)
            cvct = testfixtures.dtaFixturePath( ...
                "cv_cyclic_voltammetry_pt_reference.DTA");
            eisPath = testfixtures.dtaFixturePath( ...
                "eis_potentiostatic_zcurve.DTA");

            accepted = csc.sourceFiles.matchesDtaKind([cvct, eisPath]);

            testCase.verifyEqual(accepted, [true false]);
        end
    end
end
