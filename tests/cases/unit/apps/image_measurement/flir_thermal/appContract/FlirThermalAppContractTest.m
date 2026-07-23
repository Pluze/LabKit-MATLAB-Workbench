classdef FlirThermalAppContractTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'Unit'}), function definitionSatisfiesPublicContract(testCase), verifyAppContract(testCase, "flir_thermal"); end, end
end
