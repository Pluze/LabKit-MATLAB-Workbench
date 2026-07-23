classdef FlirThermalAppContractTest < matlab.unittest.TestCase
    methods (Test), function definitionSatisfiesPublicContract(testCase), verifyAppContract(testCase, "flir_thermal"); end, end
end
