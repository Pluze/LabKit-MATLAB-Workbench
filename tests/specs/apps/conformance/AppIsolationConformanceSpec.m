classdef AppIsolationConformanceSpec < matlab.unittest.TestCase
    %APPISOLATIONCONFORMANCESPEC Verify Apps without sibling App paths.

    methods (Test, TestTags = {'Contract:product', 'Env:isolated-process'})
        function verifiesEveryPublicAppFromAResetPathBoundary(testCase)
            [status, output] = labkittest.runIsolatedAppProbes( ...
                labkittest.publicApps());

            testCase.verifyEqual(status, 0, string(output));
        end
    end
end
