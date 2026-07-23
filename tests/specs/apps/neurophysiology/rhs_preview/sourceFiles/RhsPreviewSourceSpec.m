classdef RhsPreviewSourceSpec < matlab.unittest.TestCase
    %RHSPREVIEWSOURCESPEC Specify ordered selection of RHS source roles.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function selectsOnlyTheRequestedRoleAndPreservesSourceOrder(testCase)
            sources = [sourceRecord("filter1", "filterRecording"), ...
                sourceRecord("rhs", "recording"), ...
                sourceRecord("filter2", "filterRecording")];

            paths = rhs_preview.sourceFiles.pathsForRole(sources, "filterRecording");

            testCase.verifyEqual(paths, ["/tmp/filter1"; "/tmp/filter2"]);
        end
    end
end

function source = sourceRecord(id, role)
source = struct("id", id, "required", true, "role", role, ...
    "reference", struct("originalPath", "/tmp/" + id));
end
