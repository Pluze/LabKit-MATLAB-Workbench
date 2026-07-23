classdef RhsPreviewIsolatedPathContractTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'Integration'})
        function runsWithoutSiblingApps(testCase), verifyAppIsolatedPathContract(testCase, "neurophysiology/rhs_preview"); end
    end
end
