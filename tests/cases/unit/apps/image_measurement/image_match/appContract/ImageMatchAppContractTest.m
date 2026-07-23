classdef ImageMatchAppContractTest < matlab.unittest.TestCase
    methods (Test), function definitionSatisfiesPublicContract(testCase), verifyAppContract(testCase, "image_match"); end, end
end
