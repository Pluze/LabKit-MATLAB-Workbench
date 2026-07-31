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
    end
end
