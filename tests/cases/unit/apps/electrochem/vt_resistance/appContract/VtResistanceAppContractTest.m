classdef VtResistanceAppContractTest < matlab.unittest.TestCase
    methods (Test)
        function definitionSatisfiesPublicContract(testCase), verifyAppContract(testCase, "vt_resistance"); end
    end
end
