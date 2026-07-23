classdef CicAppContractTest < matlab.unittest.TestCase
    methods (Test)
        function definitionSatisfiesPublicContract(testCase), verifyAppContract(testCase, "cic"); end
    end
end
