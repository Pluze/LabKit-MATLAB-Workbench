classdef CscSourceSpec < matlab.unittest.TestCase
    %CSCSOURCESPEC Guard CSC project-source reconstruction.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function emptySourcesReturnTheDeclaredStructVector(testCase)
            items = csc.sourceFiles.loadProjectItems(strings(0, 1));

            testCase.verifyClass(items, "struct");
            testCase.verifySize(items, [0 0]);
        end
    end
end
