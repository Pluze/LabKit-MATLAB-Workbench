classdef CurvatureAppContractTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'Unit'}), function definitionSatisfiesPublicContract(testCase), verifyAppContract(testCase, "curvature"); end, end
end
