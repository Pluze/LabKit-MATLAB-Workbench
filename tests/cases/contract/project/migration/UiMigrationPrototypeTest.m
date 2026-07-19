classdef UiMigrationPrototypeTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'Integration', 'Architecture'})
        function representationsCompileThreeDeterministicStrictScenarios(testCase)
            root = setupLabKitTestPath();
            toolRoot = fullfile(root, "tools", "migration");
            addpath(toolRoot);
            cleanup = onCleanup(@() rmpath(toolRoot));

            report = prototypeLabKitUiContracts(root);

            testCase.verifyEqual(numel(report.valueClass.scenarios), 3);
            testCase.verifyEqual(numel(report.opaqueFunction.scenarios), 3);
            testCase.verifyTrue(all( ...
                [report.valueClass.scenarios.deterministic]));
            testCase.verifyTrue(all( ...
                [report.opaqueFunction.scenarios.deterministic]));
            testCase.verifyEqual( ...
                [report.valueClass.scenarios.targetCount], ...
                [report.opaqueFunction.scenarios.targetCount]);
            verifyStrictFailures(testCase, report.valueClass.failures);
            verifyStrictFailures(testCase, report.opaqueFunction.failures);
            clear cleanup
        end

        function evidenceSupportsValueClassDecision(testCase)
            root = setupLabKitTestPath();
            toolRoot = fullfile(root, "tools", "migration");
            addpath(toolRoot);
            cleanup = onCleanup(@() rmpath(toolRoot));

            report = prototypeLabKitUiContracts(root);

            testCase.verifyEqual(report.decision, ...
                "sealed-immutable-value-classes");
            testCase.verifyTrue( ...
                report.valueClass.helpAndMethodsDiscoverable);
            testCase.verifyFalse( ...
                report.valueClass.backingRepresentationPubliclyMutable);
            testCase.verifyTrue(report.opaqueFunction. ...
                backingRepresentationVisibleThroughFunctions);
            testCase.verifyGreaterThan( ...
                report.opaqueFunction.publicPrototypeFileCount, ...
                report.valueClass.publicPrototypeFileCount);
            testCase.verifyLessThan( ...
                report.seamComparison.valuePrototypeCoveredSeamLines, ...
                report.seamComparison.currentDistinctSeamLines);
            testCase.verifyLessThan( ...
                report.seamComparison.opaquePrototypeCoveredSeamLines, ...
                report.seamComparison.currentDistinctSeamLines);
            clear cleanup
        end

        function trackedPrototypeEvidenceMatchesFreshRun(testCase)
            root = setupLabKitTestPath();
            toolRoot = fullfile(root, "tools", "migration");
            addpath(toolRoot);
            cleanup = onCleanup(@() rmpath(toolRoot));
            outputRoot = fullfile(root, ".agents", "migration", ...
                "ui-explicit-contract");

            expected = jsondecode(fileread(fullfile(outputRoot, ...
                "phase-1-prototype-evidence.json")));
            actual = jsondecode(jsonencode( ...
                prototypeLabKitUiContracts(root)));

            testCase.verifyTrue(all( ...
                [expected.valueClass.scenarios.compileMedianSeconds] > 0));
            testCase.verifyTrue(all( ...
                [expected.opaqueFunction.scenarios.compileMedianSeconds] > 0));
            testCase.verifyEqual(withoutTimings(actual), ...
                withoutTimings(expected));
            summary = string(fileread(fullfile(outputRoot, ...
                "phase-1-prototype-evidence.md")));
            testCase.verifyTrue(contains(summary, ...
                "Decision: `sealed-immutable-value-classes`"));
            clear cleanup
        end
    end
end

function report = withoutTimings(report)
    for k = 1:numel(report.valueClass.scenarios)
        report.valueClass.scenarios(k).compileMedianSeconds = 0;
        report.opaqueFunction.scenarios(k).compileMedianSeconds = 0;
    end
end

function verifyStrictFailures(testCase, evidence)
    testCase.verifyEqual(string(evidence.unknownTarget), ...
        "prototype:ui:UnknownReference");
    testCase.verifyEqual(string(evidence.callbackRole), ...
        "prototype:ui:CallbackRoleMismatch");
    testCase.verifyEqual(string(evidence.variableArity), ...
        "prototype:ui:CallbackRoleMismatch");
    testCase.verifyEqual(string(evidence.callbackOutput), ...
        "prototype:ui:CallbackRoleMismatch");
    testCase.verifyEqual(string(evidence.unknownArgument), ...
        "labkit:ui:contract:UnknownArgument");
end
