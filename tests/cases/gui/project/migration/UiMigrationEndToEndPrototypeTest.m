classdef UiMigrationEndToEndPrototypeTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'GUI', 'Architecture'})
        function hiddenContractPassesBehaviorAndTimingGates(testCase)
            root = setupLabKitTestPath();
            toolRoot = fullfile(root, "tools", "migration");
            addpath(toolRoot);
            cleanup = onCleanup(@() rmpath(toolRoot));
            evidenceRoot = fullfile(root, ".agents", "migration", ...
                "ui-explicit-contract");

            actual = prototypeLabKitUiEndToEnd(root);
            expected = jsondecode(fileread(fullfile(evidenceRoot, ...
                "phase-1-end-to-end-evidence.json")));

            testCase.verifyTrue(actual.accepted);
            testCase.verifyTrue(actual.behaviorAccepted);
            testCase.verifyTrue(actual.timingAccepted);
            testCase.verifyFalse(actual.transaction.commitRolledBack);
            testCase.verifyEqual(actual.transaction.failureError, ...
                "prototype:ui:ActionFailed");
            testCase.verifyEqual( ...
                actual.transaction.missingCapabilityError, ...
                "prototype:ui:UndeclaredCapability");
            testCase.verifyEqual(actual.transaction.surfaceEscapeError, ...
                "prototype:ui:EscapedRenderSurface");
            testCase.verifyLessThan( ...
                actual.reconciliation.updatedAppliedOperationCount, ...
                actual.reconciliation.initialAppliedOperationCount);
            normalizedActual = jsondecode(jsonencode( ...
                withoutTimings(actual)));
            testCase.verifyEqual(normalizedActual, ...
                withoutTimings(expected));
            clear cleanup
        end
    end
end

function report = withoutTimings(report)
    fields = fieldnames(report.timings);
    for k = 1:numel(fields)
        report.timings.(fields{k}) = 0;
    end
end
