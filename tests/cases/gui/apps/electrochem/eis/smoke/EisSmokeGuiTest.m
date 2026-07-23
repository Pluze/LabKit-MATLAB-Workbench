classdef EisSmokeGuiTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'GUI', 'Smoke', 'RouteFeature:app-layout'})
        function launchesThroughAppContract(testCase)
            verifyAppSmoke(testCase, "eis");
        end
    end
end
