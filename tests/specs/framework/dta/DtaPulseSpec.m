classdef DtaPulseSpec < matlab.unittest.TestCase
    %DTAPULSESPEC Specify public pulse-detection modes and failure behavior.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function prefersValidMetadataAndFallsBackToCurrent(testCase)
            time = (0:0.01:0.25).';
            current = zeros(size(time));
            current(time >= 0.03 & time <= 0.10) = -1e-3;
            current(time >= 0.14 & time <= 0.20) = 1e-3;
            metadata = validMetadata();

            [fromMetadata, metadataMessage] = ...
                labkit.dta.detectPulses(time, current, metadata);
            [fromCurrent, currentMessage] = labkit.dta.detectPulses( ...
                time, current, metadata, "Auto from Im only");

            testCase.verifyTrue(fromMetadata.ok, metadataMessage);
            testCase.verifyEqual(fromMetadata.method, 'metadata-current');
            testCase.verifyEqual( ...
                [fromMetadata.cath.start_s, fromMetadata.cath.end_s], ...
                [0, 0.10], 'AbsTol', 1e-12);
            testCase.verifyEqual( ...
                [fromMetadata.gap.start_s, fromMetadata.gap.end_s], ...
                [0.10, 0.14], 'AbsTol', 1e-12);
            testCase.verifyTrue(fromCurrent.ok, currentMessage);
            testCase.verifyEqual(fromCurrent.method, 'auto-from-Im');
            testCase.verifyEqual( ...
                [fromCurrent.cath.start_s, fromCurrent.anod.start_s], ...
                [0.03, 0.14], 'AbsTol', 1e-12);
            testCase.verifyFalse(isfield(fromMetadata, "cath_start"));
            testCase.verifyTrue(all(isfield(fromMetadata, ...
                ["pre", "cath", "gap", "anod", "post"])));
        end

        function reportsWhenRequestedMetadataCannotProveAPulse(testCase)
            time = (0:0.01:0.25).';
            current = zeros(size(time));
            current(time >= 0.03 & time <= 0.10) = -1e-3;
            current(time >= 0.14 & time <= 0.20) = 1e-3;
            missing = struct('steps', struct('idx', {}, 'I', {}, 'V', {}, 'T', {}));

            [fallback, fallbackMessage] = labkit.dta.detectPulses(time, current, missing);
            [metadataOnly, metadataOnlyMessage] = ...
                labkit.dta.detectPulses(time, current, missing, "Metadata only");

            testCase.verifyTrue(fallback.ok, fallbackMessage);
            testCase.verifyEqual(fallback.method, 'auto-from-Im');
            testCase.verifySubstring(fallbackMessage, 'fallback success');
            testCase.verifyFalse(metadataOnly.ok);
            testCase.verifySubstring(metadataOnlyMessage, 'no ISTEP/TSTEP or VSTEP/TSTEP');
        end

        function rejectsUnknownModesInsteadOfRunningTheDefaultBranch(testCase)
            time = (0:0.01:0.25).';
            current = zeros(size(time));
            current(time >= 0.03 & time <= 0.10) = -1e-3;
            current(time >= 0.14 & time <= 0.20) = 1e-3;

            [pulse, message] = labkit.dta.detectPulses( ...
                time, current, validMetadata(), "not-a-mode");

            testCase.verifyFalse(pulse.ok);
            testCase.verifySubstring(string(message), ...
                "Unsupported pulse detection mode");
            testCase.verifyEqual(string(pulse.method), "-");
        end
    end
end

function metadata = validMetadata()
metadata = struct('steps', struct( ...
    'idx', {1, 2, 3}, ...
    'I', {-1e-3, 0, 1e-3}, ...
    'V', {NaN, NaN, NaN}, ...
    'T', {0.10, 0.04, 0.06}));
end
