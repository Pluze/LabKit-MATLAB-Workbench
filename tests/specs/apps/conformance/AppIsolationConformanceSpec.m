classdef AppIsolationConformanceSpec < matlab.unittest.TestCase
    %APPISOLATIONCONFORMANCESPEC Verify each App without sibling App paths.

    properties (TestParameter)
        App = labkittest.publicApps()
    end

    methods (Test, TestTags = {'Contract:product', 'Env:isolated-process'})
        function runsFromItsIsolatedDeployableBoundary(testCase, App)
            [status, output] = labkittest.runIsolatedAppProbe(App);

            testCase.verifyEqual(status, 0, string(output));
        end
    end
end
