classdef FocusStackIsolatedPathContractTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'Integration'})
        function runsWithoutSiblingApps(testCase), verifyAppIsolatedPathContract(testCase, "image_measurement/focus_stack"); end
    end
end
