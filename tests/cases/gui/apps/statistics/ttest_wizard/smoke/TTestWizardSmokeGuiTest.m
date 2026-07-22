classdef TTestWizardSmokeGuiTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'GUI', 'Smoke', 'RouteFeature:app-layout'})
        function launchesThroughAppContract(testCase)
            verifyAppSmoke(testCase, "ttest_wizard");
        end
    end
end
