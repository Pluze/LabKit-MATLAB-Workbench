classdef RuntimeSourceRecordTest < matlab.unittest.TestCase
    %RUNTIMESOURCERECORDTEST Verify the canonical empty source factory.

    methods (Test, TestTags = {'Unit'})
        function emptyFactoryOwnsCanonicalShape(testCase)
            setupLabKitTestPath();
            sources = labkit.ui.runtime.emptySourceRecords();
            testCase.verifySize(sources, [0 1]);
            testCase.verifyEqual(string(fieldnames(sources)), ...
                ["id"; "required"; "role"; "reference"]);
        end
    end
end
