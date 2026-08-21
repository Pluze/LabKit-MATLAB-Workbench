classdef EcgPrintStateSpec < matlab.unittest.TestCase
    %ECGPRINTSTATESPEC Specify current ECG state.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function createsCurrentDefaults(testCase)
            project = ecg_print.initialData();
            testCase.verifyNotEmpty(project.parameters.peakMethod);
        end
    end
end
