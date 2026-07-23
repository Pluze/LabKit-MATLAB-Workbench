classdef RhsPreviewSmokeGuiTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'GUI', 'Smoke', 'RouteFeature:app-layout'})
        function launchesThroughAppContract(testCase)
            verifyAppSmoke(testCase, "rhs_preview");
        end
    end
end
