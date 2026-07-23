classdef NerveResponseProjectSpec < matlab.unittest.TestCase
    %NERVERESPONSEPROJECTSPEC Specify role-identified source migration.

    methods (Test, TestTags = {'Contract:persistence', 'Env:headless'})
        function migratesTheFilterAndProtocolSourcesAndRejectsMismatches(testCase)
            spec = nerve_response_analysis.projectSpec();
            filter = sourceRecord("filterRecord", "filterRecord");
            protocol = sourceRecord("protocol", "protocol");
            project = spec.Create();
            project.inputs = struct("filterSource", filter, "protocolSource", protocol);

            migrated = spec.Migrate(project, 1);
            invalid = spec.Create();
            invalid.inputs.sources = sourceRecord("filterRecord", "protocol");

            testCase.verifyEqual(migrated.inputs.sources, [filter protocol]);
            testCase.verifyTrue(spec.Validate(migrated));
            testCase.verifyError(@() spec.Validate(invalid), ...
                "nerve_response_analysis:InvalidProject");
        end
    end
end

function source = sourceRecord(id, role)
source = struct("id", id, "required", true, "role", role, ...
    "reference", struct("originalPath", "/tmp/" + id));
end
