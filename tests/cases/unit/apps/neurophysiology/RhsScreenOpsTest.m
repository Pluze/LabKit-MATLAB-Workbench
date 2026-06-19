classdef RhsScreenOpsTest < matlab.unittest.TestCase
    %RHSSCREENOPSTEST Verify RHS screening session helpers.

    methods (Test, TestTags = {'Unit'})
        function screenFolderBuildsLightweightSession(testCase)
            setupLabKitTestPath();

            fixtureDir = tempname;
            mkdir(fixtureDir);
            cleaner = onCleanup(@() removeFolderIfPresent(fixtureDir));

            writeSyntheticRhsFixture(fullfile(fixtureDir, "accepted.rhs"), ...
                struct("nBlocks", 2, "amplifierNames", ...
                ["C-013", "C-012", "C-018"]));
            writeSyntheticRhsFixture(fullfile(fixtureDir, "short.rhs"), ...
                struct("nBlocks", 1, "amplifierNames", ...
                ["C-013", "C-012", "C-018"]));

            opts = struct("minDurationSec", 0.006, ...
                "requireExactBlocks", true, ...
                "protocol", struct("protocolId", "synthetic"));
            [session, report] = rhs_screen.ops.screenFolder(fixtureDir, opts);

            testCase.verifyEqual(report.fileCount, 2);
            testCase.verifyEqual(report.acceptedCount, 1);
            testCase.verifyEqual(report.needsReviewCount, 1);
            testCase.verifyEqual(height(session.recordings), 2);
            testCase.verifyEqual(session.type, "rhsScreenSession");
            testCase.verifyTrue(ismember("keep", session.recordings.Properties.VariableNames));
            testCase.verifyEqual(sum(session.recordings.keep), 1);
            testCase.verifyEqual(numel(session.acceptedRecordingIds), 1);
            testCase.verifyTrue(all(contains(session.recordings.channelSignature, ...
                "C-013")));

            data = rhs_screen.view.recordingsTableData(struct("session", session));
            data(:, 1) = {false};
            data{1, 9} = "manual reject";
            [session, report] = rhs_screen.ops.applyRecordingsTableData(session, data);
            testCase.verifyEqual(report.keptCount, 0);
            testCase.verifyEmpty(session.acceptedRecordingIds);
            testCase.verifyEqual(session.recordings.reviewNote(1), "manual reject");

            payload = rhs_screen.export.sessionJsonStruct(session);
            testCase.verifyEqual(numel(payload.recordings), 2);
            testCase.verifyEqual(payload.exportedBy, "labkit_RHSScreen_app");
        end

        function summaryAndDetailsRenderDefaultState(testCase)
            setupLabKitTestPath();

            rows = rhs_screen.view.summaryTableData(struct());
            lines = rhs_screen.view.detailLines(struct());

            testCase.verifyEqual(size(rows, 2), 2);
            testCase.verifyTrue(iscell(lines));
            testCase.verifyFalse(isempty(lines));
        end
    end
end

function removeFolderIfPresent(folder)
    if exist(folder, "dir") == 7
        rmdir(folder, "s");
    end
end
