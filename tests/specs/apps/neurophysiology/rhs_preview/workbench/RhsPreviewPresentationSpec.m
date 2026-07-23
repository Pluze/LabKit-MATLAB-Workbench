classdef RhsPreviewPresentationSpec < matlab.unittest.TestCase
    %RHSPREVIEWPRESENTATIONSPEC Specify human-readable RHS preview state.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function presentsDefaultSummaryAndChannelNamesWithoutSourcePaths(testCase)
            state = struct("rhsFile", fullfile("synthetic", "primary.rhs"), ...
                "info", struct("channelFamilies", struct("amplifier", ...
                struct("nativeName", {"C-001", "C-002"}))));

            summary = rhs_preview.analysisRun.summaryTableData(state);
            details = rhs_preview.analysisRun.detailLines(state);
            joined = string(strjoin(details, newline));

            testCase.verifyEqual(size(summary, 2), 2);
            testCase.verifyTrue(any(string(summary(:, 1)) == "RHS file"));
            testCase.verifySubstring(joined, "C-001");
            testCase.verifyFalse(contains(joined, "synthetic/primary.rhs"));
        end
    end
end
