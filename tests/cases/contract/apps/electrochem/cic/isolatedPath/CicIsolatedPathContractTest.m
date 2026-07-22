classdef CicIsolatedPathContractTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'Integration'})
        function runsWithoutSiblingApps(testCase), verifyAppIsolatedPathContract(testCase, "electrochem/cic"); end
    end
end
