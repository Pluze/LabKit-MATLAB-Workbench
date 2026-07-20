classdef GitHubTemplateContractTest < matlab.unittest.TestCase
    %GITHUBTEMPLATECONTRACTTEST GitHub contribution templates stay actionable.

    methods (Test, TestTags = {'Integration', 'Style'})
        function templatesUseCurrentHandoffContract(testCase)
            root = setupLabKitTestPath();
            prTemplate = string(fileread(fullfile(root, ".github", ...
                "PULL_REQUEST_TEMPLATE.md")));
            workflowTemplate = string(fileread(fullfile(root, ".github", ...
                "ISSUE_TEMPLATE", "workflow_request.md")));
            bugTemplate = string(fileread(fullfile(root, ".github", ...
                "ISSUE_TEMPLATE", "bug_report.md")));

            testCase.verifyTrue(contains(prTemplate, ...
                "docs/development/maintain-and-release/testing.md"));
            testCase.verifyTrue(contains(prTemplate, ...
                "docs/history/records/**/*.md"));
            testCase.verifyFalse(contains(prTemplate, ...
                "docs/development/testing.md"));
            testCase.verifyTrue(contains(prTemplate, "## Goal and scope"));
            testCase.verifyTrue(contains(prTemplate, "## Delivery state"));
            testCase.verifyTrue(contains(workflowTemplate, ...
                "## Acceptance criteria"));
            testCase.verifyTrue(contains(workflowTemplate, "## Out of scope"));
            testCase.verifyTrue(contains(bugTemplate, "## Impact and workaround"));
        end
    end
end
