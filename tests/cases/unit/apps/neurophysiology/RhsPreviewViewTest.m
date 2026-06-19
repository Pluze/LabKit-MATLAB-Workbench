classdef RhsPreviewViewTest < matlab.unittest.TestCase
    %RHSPREVIEWVIEWTEST Verify RHS Preview display helpers.

    methods (Test, TestTags = {'Unit'})
        function summaryAndDetailsRenderDefaultState(testCase)
            setupLabKitTestPath();

            rows = rhs_preview.view.summaryTableData(struct());
            lines = rhs_preview.view.detailLines(struct());

            testCase.verifyTrue(iscell(rows));
            testCase.verifyGreaterThanOrEqual(size(rows, 1), 4);
            testCase.verifyEqual(size(rows, 2), 2);
            testCase.verifyTrue(iscell(lines));
            testCase.verifyFalse(isempty(lines));
        end

        function detailLinesShowChannelNamesWithoutPaths(testCase)
            setupLabKitTestPath();

            S = struct();
            S.info = struct();
            S.info.channelFamilies = struct();
            S.info.channelFamilies.amplifier = struct( ...
                "nativeName", {"C-001", "C-002"});
            S.rhsFile = fullfile("synthetic", "primary.rhs");
            lines = rhs_preview.view.detailLines(S);

            joined = string(strjoin(lines, newline));
            testCase.verifyTrue(contains(joined, "C-001"));
            testCase.verifyFalse(contains(joined, "synthetic/primary.rhs"));
        end

        function channelRowsBuildPreviewAndChannelProtocolDraft(testCase)
            setupLabKitTestPath();

            info = struct();
            info.channelFamilies = struct();
            info.channelFamilies.amplifier = struct( ...
                "nativeName", {"C-001", "C-002", "C-003"}, ...
                "customName", {"C-001", "C-002", "C-003"});
            protocol = struct("channels", struct( ...
                "roles", struct( ...
                    "id", "reference", ...
                    "label", "Reference", ...
                    "match", struct("anyNativeName", {{"C-002"}})), ...
                "pairs", struct( ...
                    "id", "legacy_pair", ...
                    "positive", "reference", ...
                    "negative", "ground")));

            rows = rhs_preview.ops.channelRows(info, "amplifier", 2, protocol);

            testCase.verifyEqual(height(rows), 3);
            testCase.verifyEqual(rows.preview(:), [true; true; false]);
            testCase.verifyEqual(rows.role(2), "reference");

            S = struct("previewChannelRows", rows);
            payload = rhs_preview.export.protocolJsonStruct(S);

            testCase.verifyEqual(payload.schemaVersion, "labkit.rhs.protocol.v1");
            testCase.verifyEqual(payload.channels.roles.id, "reference");
            testCase.verifyEqual(string(payload.channels.roles.nativeName), "C-002");
            testCase.verifyFalse(isfield(payload.channels, "pairs"));
            testCase.verifyFalse(isfield(payload, "preview"));

            S.protocol = struct( ...
                "schemaVersion", "labkit.rhs.protocol.v1", ...
                "protocolId", "loaded_protocol", ...
                "label", "Loaded Protocol", ...
                "channels", struct("roles", struct( ...
                    "id", "reference", ...
                    "nativeName", "C-002")), ...
                "eventDetection", struct("sources", struct( ...
                    "id", "manual_marks", ...
                    "kind", "manual")));
            payload = rhs_preview.export.protocolJsonStruct(S);

            testCase.verifyEqual(payload.protocolId, "loaded_protocol");
            testCase.verifyEqual(payload.channels.roles.id, "reference");
            testCase.verifyFalse(isfield(payload, "eventDetection"));
        end

        function filterRowsExportManualLabels(testCase)
            setupLabKitTestPath();

            fixtureDir = tempname;
            mkdir(fixtureDir);
            cleaner = onCleanup(@() removeFolderIfPresent(fixtureDir));

            writeSyntheticRhsFixture(fullfile(fixtureDir, "first.rhs"), ...
                struct("nBlocks", 1, "amplifierNames", "C-001"));
            nestedDir = fullfile(fixtureDir, "nested");
            mkdir(nestedDir);
            writeSyntheticRhsFixture(fullfile(nestedDir, "second.rhs"), ...
                struct("nBlocks", 1, "amplifierNames", "C-002"));

            rows = rhs_preview.ops.discoverFilterRows(fixtureDir);
            testCase.verifyEqual(height(rows), 2);
            testCase.verifyTrue(all(rows.label == "good"));

            data = rhs_preview.view.fileFilterTableData(struct("filterRows", rows));
            data{2, 1} = "bad";
            data{2, 3} = "manual reject";
            rows = rhs_preview.ops.applyFileFilterTableData(rows, data);
            payload = rhs_preview.export.filterRecordJsonStruct( ...
                struct("rhsFolder", fixtureDir, "filterRows", rows));

            testCase.verifyEqual(payload.type, "rhsFilterRecord");
            testCase.verifyEqual(numel(payload.recordings), 2);
            testCase.verifyEqual(string(payload.recordings(2).label), "bad");
            testCase.verifyEqual(string(payload.recordings(2).comment), ...
                "manual reject");
        end
    end
end

function removeFolderIfPresent(folder)
    if exist(folder, "dir") == 7
        rmdir(folder, "s");
    end
end
