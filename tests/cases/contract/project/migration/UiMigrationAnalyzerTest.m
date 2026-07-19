classdef UiMigrationAnalyzerTest < matlab.unittest.TestCase
    methods (Test, TestTags = {'Integration', 'Architecture'})
        function analyzerReportsLocationsWorksheetAndGuard(testCase)
            root = setupLabKitTestPath();
            toolRoot = fullfile(root, "tools", "migration");
            addpath(toolRoot);
            cleanup = onCleanup(@() rmpath(toolRoot));
            outputRoot = fullfile(root, ".agents", "migration", ...
                "ui-explicit-contract");
            scratch = string(tempname);
            scratchCleanup = onCleanup(@() removeFolder(scratch));

            report = analyzeLabKitUiMigration(root, ...
                Write=true, OutputRoot=scratch);

            testCase.verifyEqual(report.summary.appCount, 21);
            categories = string({report.diagnostics.category});
            required = [ ...
                "definition-field"
                "definition-call"
                "layout-constructor"
                "raw-presentation-path"
                "interaction-kind"
                "interaction-field"
                "interaction-option"
                "event-decoding"
                "service-call"
                "callback-signature"
                "retired-callback-context"
                "undocumented-alias"];
            testCase.verifyEmpty(setdiff(required, categories));
            testCase.verifyTrue(all([report.diagnostics.line] > 0));
            testCase.verifyTrue(all(strlength( ...
                string({report.diagnostics.source})) > 0));
            testCase.verifyTrue(all(strlength( ...
                string({report.diagnostics.replacement})) > 0));
            testCase.verifyGreaterThan( ...
                report.summary.worksheetEntryCount, 100);
            testCase.verifyGreaterThan( ...
                report.summary.retiredDiagnosticCount, 100);
            layoutDiagnostics = report.diagnostics( ...
                categories == "layout-constructor");
            rawPresentation = report.diagnostics( ...
                categories == "raw-presentation-path");
            testCase.verifyFalse(any([layoutDiagnostics.retired]));
            testCase.verifyTrue(all([rawPresentation.retired]));

            worksheet = string(fileread(fullfile(outputRoot, ...
                "migration-worksheet.md")));
            testCase.verifyTrue(contains(worksheet, ...
                "# UI migration worksheet"));
            regenerated = string(fileread(fullfile(scratch, ...
                "migration-worksheet.md")));
            testCase.verifyEqual(regenerated, worksheet);
            testCase.verifyFalse(isfile(fullfile(scratch, ...
                "migration-analysis.json")));

            video = analyzeLabKitUiMigration(root, App="video-marker");
            testCase.verifyEqual(video.summary.appCount, 1);
            testCase.verifyTrue(all( ...
                string({video.diagnostics.appId}) == "video-marker"));
            testCase.verifyError(@() analyzeLabKitUiMigration( ...
                root, App="not-an-app"), ...
                "LabKit:Migration:UnknownApp");
            testCase.verifyError(@() analyzeLabKitUiMigration( ...
                root, App="video-marker", FailOnRetired=true), ...
                "LabKit:Migration:RetiredUiBoundary");
            clear scratchCleanup
            clear cleanup
        end
    end
end

function removeFolder(folder)
    if isfolder(folder)
        rmdir(folder, "s");
    end
end
