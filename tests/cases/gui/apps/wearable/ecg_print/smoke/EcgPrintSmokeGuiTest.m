classdef EcgPrintSmokeGuiTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'GUI', 'Smoke', 'RouteFeature:app-layout'})
        function launchesThroughAppContract(testCase)
            verifyAppSmoke(testCase, "ecg_print");
        end
    end
end
