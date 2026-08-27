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

        function windowAndChannelsRefitWhileRoiOverlayPreservesView(testCase)
            applicationState = struct("project", struct("inputs", struct( ...
                "sources", labkit.app.source.record( ...
                    "recording-a", "recording", "synthetic.rhs"))));
            context = struct("family", "amplifier", ...
                "preview", struct("channels", ["A-001" "A-002"], ...
                    "timeSec", [0; 0.01; 0.02]), ...
                "roiSec", [0.005 0.015]);
            sources = applicationState.project.inputs.sources;
            base = rhs_preview.analysisRun.viewportRevision( ...
                sources, context.family, context.preview);

            context.roiSec = [0.01 0.02];
            testCase.verifyEqual( ...
                revisionFor(sources, context), base);
            context.preview.timeSec = [0.02; 0.03; 0.04];
            testCase.verifyNotEqual( ...
                revisionFor(sources, context), base);
            context.preview.timeSec = [0; 0.01; 0.02];
            context.preview.channels = "A-003";
            testCase.verifyNotEqual( ...
                revisionFor(sources, context), base);
            context.preview.channels = ["A-001" "A-002"];
            context.family = "boardAdc";
            testCase.verifyNotEqual( ...
                revisionFor(sources, context), base);
        end
    end
end

function revision = revisionFor(sources, context)
revision = rhs_preview.analysisRun.viewportRevision( ...
    sources, context.family, context.preview);
end
