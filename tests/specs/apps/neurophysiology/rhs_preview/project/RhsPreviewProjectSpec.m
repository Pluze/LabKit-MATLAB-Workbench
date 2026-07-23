classdef RhsPreviewProjectSpec < matlab.unittest.TestCase
    %RHSPREVIEWPROJECTSPEC Specify migration to one role-tagged source list.

    methods (Test, TestTags = {'Contract:persistence', 'Env:headless'})
        function migratesRoleSpecificSourcesWithoutChangingTheirOrder(testCase)
            spec = rhs_preview.projectSpec();
            rhs = sourceRecord("rhs", "recording");
            protocol = sourceRecord("protocol", "protocol");
            filters = [sourceRecord("filter1", "filterRecording"), ...
                sourceRecord("filter2", "filterRecording")];
            project = spec.Create();
            project.inputs = struct("rhsSource", rhs, "protocolSource", protocol, ...
                "filterSources", filters);

            migrated = spec.Migrate(project, 1);

            testCase.verifyEqual(migrated.inputs.sources, [rhs protocol filters]);
            testCase.verifyFalse(any(isfield(migrated.inputs, ...
                {'rhsSource', 'protocolSource', 'filterSources'})));
            testCase.verifyTrue(spec.Validate(migrated));
        end
    end
end

function source = sourceRecord(id, role)
source = struct("id", id, "required", true, "role", role, ...
    "reference", struct("originalPath", "/tmp/" + id));
end
