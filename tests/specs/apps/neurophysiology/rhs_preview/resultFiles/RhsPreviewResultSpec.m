classdef RhsPreviewResultSpec < matlab.unittest.TestCase
    %RHSPREVIEWRESULTSPEC Specify compact protocol and file-filter JSON data.

    methods (Test, TestTags = {'Contract:result', 'Env:headless'})
        function serializesAssignedChannelRolesWithoutPreviewOnlyFields(testCase)
            rows = table([true; false], ["reference"; ""], ...
                ["Reference"; "C-003"], ["C-002"; "C-003"], ...
                'VariableNames', {'preview', 'role', 'label', 'channel'});

            payload = rhs_preview.resultFiles.protocolJsonStruct( ...
                struct("previewChannelRows", rows));

            testCase.verifyEqual(payload.schemaVersion, "labkit.rhs.protocol.v1");
            testCase.verifyEqual(payload.channels.roles.id, "reference");
            testCase.verifyEqual(payload.channels.roles.nativeName, "C-002");
            testCase.verifyFalse(isfield(payload, "preview"));
        end

        function preservesManualFilterLabelsAndComments(testCase)
            rows = table(["first.rhs"; "second.rhs"], ["good"; "bad"], ...
                [""; "manual reject"], 'VariableNames', {'file', 'label', 'comment'});

            payload = rhs_preview.resultFiles.filterRecordJsonStruct( ...
                struct("rhsFolder", "/tmp/filters", "filterRows", rows));

            testCase.verifyEqual(payload.type, "rhsFilterRecord");
            testCase.verifyEqual(numel(payload.recordings), 2);
            testCase.verifyEqual(string(payload.recordings(2).label), "bad");
            testCase.verifyEqual(string(payload.recordings(2).comment), "manual reject");
        end
    end
end
