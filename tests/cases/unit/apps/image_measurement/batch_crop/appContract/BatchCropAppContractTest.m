classdef BatchCropAppContractTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'Unit'}), function definitionSatisfiesPublicContract(testCase), verifyAppContract(testCase, "batch_crop"); end, end
end
