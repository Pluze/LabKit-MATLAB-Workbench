classdef ChronoOverlayAppContractTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'Unit'})
        function definitionSatisfiesPublicContract(testCase), verifyAppContract(testCase, "chrono_overlay"); end
    end
end
