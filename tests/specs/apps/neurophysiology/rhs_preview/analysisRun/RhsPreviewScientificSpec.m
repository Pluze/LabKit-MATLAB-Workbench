classdef RhsPreviewScientificSpec < matlab.unittest.TestCase
    %RHSPREVIEWSCIENTIFICSPEC Specify channel-role and preview-window values.

    methods (Test, TestTags = {'Contract:scientific', 'Env:headless'})
        function assignsProtocolRolesAndAStableDefaultPreviewSubset(testCase)
            info = struct("channelFamilies", struct("amplifier", struct( ...
                "nativeName", {"C-001", "C-002", "C-003"}, ...
                "customName", {"C-001", "C-002", "C-003"})));
            protocol = struct("channels", struct("roles", struct( ...
                "id", "reference", "label", "Reference", ...
                "match", struct("anyNativeName", {{"C-002"}}))));

            rows = rhs_preview.analysisRun.channelRows(info, "amplifier", 2, protocol);

            testCase.verifyEqual(rows.preview(:), [true; true; false]);
            testCase.verifyEqual(rows.role(2), "reference");
            testCase.verifyEqual(rows.unit(1), "microvolts");
        end

        function derivesLegalWindowBoundsFromIndexedTiming(testCase)
            state = struct("index", struct("durationSec", 12, ...
                "info", struct("sampleRateHz", 2000)), "windowDurationSec", 3);

            bounds = rhs_preview.analysisRun.previewWindowBounds(state);

            testCase.verifyTrue(bounds.hasIndexedDuration);
            testCase.verifyEqual(bounds.maxStartSec, 9);
            testCase.verifyEqual(bounds.minDurationSec, .025, AbsTol=1e-12);
        end
    end
end
