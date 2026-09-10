classdef NIDmmRecordingStateSpec < matlab.unittest.TestCase
    % NIDMMRECORDINGSTATESPEC Invariant: delivered batches retain values and synchronization timestamps before presentation.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function provesNIDmmRecordingState(testCase)
            buffer = ni_dmm_recorder.recording.createBuffer();
            box = containers.Map("KeyType", "char", "ValueType", "any");
            posts = containers.Map("KeyType", "char", "ValueType", "any");
            posts("count") = 0;
            context = labkittest.createCallbackContext(struct( ...
                "postEvent", @(~, ~) increment(posts)));
            timestamp = datetime(2026, 1, 2, 3, 4, 5, "TimeZone", "UTC");
            samples = [sampleAt(timestamp, 0.02, 200, true); ...
                sampleAt(timestamp + seconds(0.02), 0.04, NaN, false)];
            ni_dmm_recorder.recording.receiveSamples(box, buffer, context, ...
                struct("Type", "labkit.nidmm.connection"), samples);
            testCase.verifyEqual(buffer("sampleCount"), 2);
            testCase.verifyEqual(buffer("validCount"), 1);
            testCase.verifyEqual(buffer("invalidCount"), 1);
            testCase.verifyEqual(buffer("timestampUTC"), ...
                [timestamp; timestamp + seconds(0.02)]);
            testCase.verifyEqual(buffer("plotValue"), 200);
            testCase.verifyEqual(posts("count"), 1);
        end
    end
end

function value = sampleAt(timestamp, elapsed, measurement, valid)
value = struct("Valid", valid, "Value", measurement, "Unit", "ohm", ...
    "Mode", "resistance_4wire", "Range", 1000, "Digits", 5.5, ...
    "Sequence", round(elapsed / 0.02), "Elapsed_s", elapsed, ...
    "TimestampUTC", timestamp, "ReceivedAtUTC", timestamp + seconds(0.001), ...
    "TimeUncertainty_s", 0.02, "FailureStatus", "");
if ~valid
    value.FailureStatus = "synthetic_failure";
end
end

function posts = increment(posts)
posts("count") = posts("count") + 1;
end
