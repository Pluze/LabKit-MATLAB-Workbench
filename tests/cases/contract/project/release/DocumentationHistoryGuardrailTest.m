classdef DocumentationHistoryGuardrailTest < matlab.unittest.TestCase
    %DOCUMENTATIONHISTORYGUARDRAILTEST Guard distributed component history.

    methods (Test, TestTags = {'Integration', 'Style'})
        function historyUsesDistributedMarkdownRecords(testCase)
            root = setupLabKitTestPath();
            entries = dir(fullfile(root, "docs", "**", "history", "**", "*.md"));
            testCase.verifyGreaterThanOrEqual(numel(entries), 50, ...
                "Recorded project evolution should remain available after migration.");
            testCase.verifyFalse(isfile(fullfile(root, "CHANGELOG.md")), ...
                "History belongs with component documentation, not a root giant file.");
            testCase.verifyFalse(isfile(fullfile(root, "tools", "release", ...
                "parseLabKitChangelog.m")), ...
                "Documentation history should not require a separate release parser.");
        end

        function historyRecordsKeepUniqueStructuredIdentity(testCase)
            root = setupLabKitTestPath();
            entries = dir(fullfile(root, "docs", "**", "history", "**", "*.md"));
            ids = strings(numel(entries), 1);
            missing = strings(0, 1);
            requiredHeadings = [ ...
                "## Context", "## Decision and rationale", "## Changes", ...
                "## User and data impact", "## Compatibility and migration", ...
                "## Validation", "## Evidence", ...
                "## Known limitations and follow-up"];
            for k = 1:numel(entries)
                filepath = fullfile(entries(k).folder, entries(k).name);
                text = string(fileread(filepath));
                ids(k) = metadataValue(text, "id");
                valid = strlength(ids(k)) > 0 && ...
                    strlength(metadataValue(text, "date")) > 0 && ...
                    strlength(metadataValue(text, "type")) > 0 && ...
                    strlength(metadataValue(text, "compatibility")) > 0 && ...
                    all(contains(text, requiredHeadings));
                if ~valid
                    missing(end + 1) = string(filepath);
                end
            end
            testCase.verifyEmpty(missing, ...
                "History records should retain identity and decision sections.");
            testCase.verifyEqual(numel(unique(ids)), numel(ids), ...
                "Distributed history Change IDs must remain unique.");
        end

        function generatedPagesAggregateRelatedHistory(testCase)
            root = setupLabKitTestPath();
            historyIndex = string(fileread(fullfile(root, "site", ...
                "history", "index.html")));
            dicPage = string(fileread(fullfile(root, "site", "apps", ...
                "dic", "dic-preprocess.html")));
            frameworkPage = string(fileread(fullfile(root, "site", ...
                "framework", "index.html")));

            testCase.verifyTrue(contains(historyIndex, "Change history"));
            testCase.verifyTrue(contains(dicPage, "Change history") && ...
                contains(dicPage, "dic-rigid-point-editor"));
            testCase.verifyTrue(contains(frameworkPage, "Change history") && ...
                contains(frameworkPage, "runtime-v2-app-migration"));
        end
    end
end

function value = metadataValue(text, key)
    token = regexp(text, "(?m)^" + key + ":\s*(\S+)\s*$", ...
        "tokens", "once");
    if isempty(token)
        value = "";
    else
        value = string(token{1});
    end
end
