classdef FocusStackAppContractTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'Unit'}), function definitionSatisfiesPublicContract(testCase), verifyAppContract(testCase, "focus_stack"); end, end
end
