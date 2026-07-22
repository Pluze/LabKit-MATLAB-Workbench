classdef ImageMatchSmokeGuiTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'GUI', 'Smoke', 'RouteFeature:app-layout'})
        function launchesThroughAppContract(testCase)
            verifyAppSmoke(testCase, "image_match");
        end
    end
end
