classdef UiMigrationBaselineTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'Integration', 'Architecture'})
        function auditCoversEveryDiscoveredAppAndCurrentBoundary(testCase)
            root = setupLabKitTestPath();
            toolRoot = fullfile(root, "tools", "migration");
            addpath(toolRoot);
            cleanup = onCleanup(@() rmpath(toolRoot));

            report = auditLabKitUiMigration(root);
            apps = discoverLabKitApps();

            testCase.verifyEqual(report.summary.appCount, height(apps));
            testCase.verifyEqual(sort(string({report.apps.command})).', ...
                sort(apps.Command));
            testCase.verifyGreaterThan(report.summary.publicUiSymbolCount, 20);
            testCase.verifyGreaterThan(report.summary.matchCount, 100);
            testCase.verifyTrue(any(string({report.matches.category}) == ...
                "presentation-transport"));
            testCase.verifyTrue(any(string({report.matches.category}) == ...
                "service-call"));
            testCase.verifyTrue(any(string({report.matches.category}) == ...
                "interaction-kind"));
            frameworkCategories = string({report.frameworkMatches.category});
            required = [ ...
                "definition-field"
                "project-field"
                "layout-field"
                "layout-binding-field"
                "presentation-root"
                "control-presentation-field"
                "preview-field"
                "interaction-field"
                "service-group"
                "service-operation"
                "event-field"
                "resource-field"
                "result-field"
                "state-bucket"
                "state-root"
                "callback-arity-probe"];
            testCase.verifyEmpty(setdiff(required, frameworkCategories));
            testCase.verifyEqual( ...
                report.summary.prohibitedArchitectureNameCount, 0);
            testCase.verifyFalse(any( ...
                string({report.callPatternClassifications.disposition}) == ...
                "unclassified"));
            clear cleanup
        end

        function trackedEvidenceMatchesFreshAudit(testCase)
            root = setupLabKitTestPath();
            toolRoot = fullfile(root, "tools", "migration");
            addpath(toolRoot);
            cleanup = onCleanup(@() rmpath(toolRoot));
            outputRoot = fullfile(root, ".agents", "migration", ...
                "ui-explicit-contract");
            expected = jsondecode(fileread(fullfile(outputRoot, ...
                "baseline.json")));
            actual = jsondecode(jsonencode(auditLabKitUiMigration(root)));

            testCase.verifyEqual(actual, expected);
            matrix = string(fileread(fullfile(outputRoot, ...
                "capability-matrix.md")));
            testCase.verifyTrue(contains(matrix, ...
                "# UI explicit-contract Phase 0 capability matrix"));
            testCase.verifyEqual(count(matrix, newline + "| "), ...
                actual.summary.appCount + 2);
            classification = string(fileread(fullfile(outputRoot, ...
                "behavior-classification.md")));
            testCase.verifyTrue(contains(classification, ...
                "# Current UI call-pattern classification"));
            performance = jsondecode(fileread(fullfile(outputRoot, ...
                "performance-baseline.json")));
            testCase.verifyEqual(numel(performance.scenarios), 3);
            testCase.verifyTrue(all( ...
                [performance.scenarios.startupMedianSeconds] > 0));
            phaseEvidence = string(fileread(fullfile(outputRoot, ...
                "phase-0-evidence.md")));
            testCase.verifyTrue(contains(phaseEvidence, ...
                "passed 21 of 21 tests"));
            clear cleanup
        end
    end
end
