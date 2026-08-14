classdef Mark10AcquisitionSpec < matlab.unittest.TestCase
    %MARK10ACQUISITIONSPEC Specify monitor rate and bounded buffer defaults.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function mapsDeclaredRatesAndCreatesEmptyBuffer(testCase)
            buffer = mark10_monitor.acquisition.createBuffer();

            testCase.verifyEqual(mark10_monitor.acquisition.ratePeriod("5 Hz"), 0.2);
            testCase.verifyEqual(mark10_monitor.acquisition.ratePeriod("Maximum"), 0.001);
            testCase.verifyEmpty(buffer("plotTime_s"));
            testCase.verifyFalse(buffer("recording"));
            testCase.verifyError(@() ...
                mark10_monitor.acquisition.ratePeriod("unsupported"), ...
                "mark10_monitor:InvalidRate");
        end
    end
end
