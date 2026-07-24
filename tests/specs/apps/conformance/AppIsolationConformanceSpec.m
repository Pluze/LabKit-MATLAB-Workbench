classdef AppIsolationConformanceSpec < matlab.unittest.TestCase
    %APPISOLATIONCONFORMANCESPEC Verify Apps without sibling App paths.

    methods (Test, TestTags = {'Contract:product', 'Env:path-isolated'})
        function verifiesEveryPublicAppFromAResetPathBoundary(testCase)
            apps = labkittest.publicApps();
            previousPath = path;
            previousFolder = pwd;
            [status, output] = labkittest.runIsolatedAppProbes( ...
                apps);

            testCase.verifyEqual(status, 0, string(output));
            testCase.verifyEqual(path, previousPath);
            testCase.verifyEqual(pwd, previousFolder);
        end
    end
end
