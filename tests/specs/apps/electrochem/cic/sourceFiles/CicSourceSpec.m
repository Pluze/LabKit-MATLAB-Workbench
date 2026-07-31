classdef CicSourceSpec < matlab.unittest.TestCase
    %CICSOURCESPEC Guard CIC project-source reconstruction.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function emptySourcesReturnTheDeclaredStructVector(testCase)
            project = cic.projectSpec().Create();

            items = cic.sourceFiles.loadProjectItems( ...
                strings(0, 1), project.parameters);

            testCase.verifyClass(items, "struct");
            testCase.verifySize(items, [0 0]);
        end
    end
end
