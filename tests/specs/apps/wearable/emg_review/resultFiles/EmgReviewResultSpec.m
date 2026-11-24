classdef EmgReviewResultSpec < matlab.unittest.TestCase
    methods (Test, TestTags={'Contract:result','Env:headless'})
        function csvRetainsMeasuredValuesAndTheirBasis(testCase)
            folder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            output = fullfile(folder, "metrics.csv");
            source = table([1;2], [12.5;NaN], 'VariableNames', {'Pair','SNR_dB'});
            session = struct('result', struct('metrics', source), 'channel', "Lead", ...
                'signal', struct('unit', "mV", 'fs', 321), 'band', "As recorded");
            context = labkittest.createCallbackContext(struct( ...
                "chooseOutputFile", @(~,~) labkit.app.dialog.Choice(output), ...
                "log", @(varargin) []));
            emg_review.resultFiles.exportMetrics(struct('session', session), context);
            result = readtable(output, TextType="string");
            testCase.verifyEqual(result.Pair, [1;2]);
            testCase.verifyEqual(result.SNR_dB(1), 12.5);
            testCase.verifyTrue(isnan(result.SNR_dB(2)));
            testCase.verifyEqual(result.Channel, ["Lead";"Lead"]);
            testCase.verifyEqual(result.Unit, ["mV";"mV"]);
            testCase.verifyEqual(result.SampleRate_Hz, [321;321]);
            testCase.verifyEqual(result.MeasurementBand, ["As recorded";"As recorded"]);
        end
    end
end
