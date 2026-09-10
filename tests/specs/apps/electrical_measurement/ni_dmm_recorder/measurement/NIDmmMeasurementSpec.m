classdef NIDmmMeasurementSpec < matlab.unittest.TestCase
    % NIDMMMEASUREMENTSPEC Invariant: App labels map to explicit facade modes, ranges, digits, and rates.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function provesNIDmmMeasurement(testCase)
            request = ni_dmm_recorder.measurement.configuration(struct( ...
                "mode", "2-Wire Resistance", "rangeMode", "Fixed", ...
                "fixedRange", 1000, "digits", "5.5", "rate", "40 Hz"));
            testCase.verifyEqual(request.Mode, "resistance_2wire");
            testCase.verifyEqual(request.Range, 1000);
            testCase.verifyEqual(request.Digits, 5.5);
            testCase.verifyEqual(request.Rate_Hz, 40);

            automatic = ni_dmm_recorder.measurement.configuration(struct( ...
                "mode", "DC Voltage", "rangeMode", "Automatic", ...
                "fixedRange", 10, "digits", "6.5", "rate", "10 Hz"));
            testCase.verifyEqual(automatic.Mode, "dc_voltage");
            testCase.verifyEqual(automatic.Range, "auto");
            testCase.verifyEqual(automatic.Rate_Hz, 10);
        end
    end
end
