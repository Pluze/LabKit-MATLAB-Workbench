classdef DocumentationHistoryGuardrailTest < matlab.unittest.TestCase
    %DOCUMENTATIONHISTORYGUARDRAILTEST Guard centralized history records.

    methods (Test, TestTags = {'Integration', 'Style'})
        function historyUsesCentralMarkdownRecords(testCase)
            root = setupLabKitTestPath();
            historyRoot = fullfile(root, "docs", "history", "records");
            entries = dir(fullfile(historyRoot, "**", "*.md"));
            testCase.verifyGreaterThanOrEqual(numel(entries), 50, ...
                "Recorded project evolution should remain available after migration.");
            allHistory = dir(fullfile(root, "docs", "**", "history", ...
                "**", "*.md"));
            nonRecordPages = ["README.md", "record-format.md"];
            allHistory = allHistory(~ismember( ...
                string({allHistory.name}), nonRecordPages));
            testCase.verifyTrue(all(startsWith( ...
                string({allHistory.folder}), string(historyRoot))), ...
                "History records should have one predictable source directory.");
            testCase.verifyFalse(isfile(fullfile(root, "CHANGELOG.md")), ...
                "History uses individual records, not a root giant file.");
            testCase.verifyFalse(isfile(fullfile(root, "tools", "release", ...
                "parseLabKitChangelog.m")), ...
                "Documentation history should not require a separate release parser.");
        end

        function historyRecordsKeepUniqueStructuredIdentity(testCase)
            root = setupLabKitTestPath();
            entries = dir(fullfile(root, "docs", "history", "records", ...
                "**", "*.md"));
            ids = strings(numel(entries), 1);
            dates = strings(numel(entries), 1);
            sequences = NaN(numel(entries), 1);
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
                dates(k) = metadataValue(text, "date");
                sequences(k) = str2double(metadataValue(text, "sequence"));
                valid = strlength(ids(k)) > 0 && ...
                    strlength(dates(k)) > 0 && ...
                    isfinite(sequences(k)) && sequences(k) > 0 && ...
                    fix(sequences(k)) == sequences(k) && ...
                    strlength(metadataValue(text, "type")) > 0 && ...
                    strlength(metadataValue(text, "compatibility")) > 0 && ...
                    ~contains(text, newline + "schema:") && ...
                    ~contains(text, newline + "introduced:") && ...
                    ~isempty(regexp(text, '(?m)^scope: \S.*$', "once")) && ...
                    all(contains(text, requiredHeadings));
                if ~valid
                    missing(end + 1) = string(filepath);
                end
            end
            testCase.verifyEmpty(missing, ...
                "History records should retain identity and decision sections.");
            testCase.verifyEqual(numel(unique(ids)), numel(ids), ...
                "History Change IDs must remain unique.");
            testCase.verifyEqual(sort(sequences), (1:numel(entries)).', ...
                ["History sequence values must be unique and contiguous so " ...
                "same-day changes retain one explicit linear order."]);
            [~, chronologicalOrder] = sort(sequences);
            orderedDates = dates(chronologicalOrder);
            testCase.verifyEqual(orderedDates, sort(orderedDates), ...
                "History sequence must not move backward across dates.");
        end

        function generatedTimelineUsesHistorySequence(testCase)
            root = setupLabKitTestPath();
            entries = dir(fullfile(root, "docs", "history", "records", ...
                "**", "*.md"));
            sequences = NaN(numel(entries), 1);
            expected = strings(numel(entries), 1);
            historyRoot = fullfile(root, "docs", "history");
            for k = 1:numel(entries)
                filepath = fullfile(entries(k).folder, entries(k).name);
                text = string(fileread(filepath));
                sequences(k) = str2double(metadataValue(text, "sequence"));
                relative = extractAfter(string(filepath), ...
                    string(historyRoot) + filesep);
                expected(k) = erase(replace(relative, filesep, "/"), ".md") + ...
                    ".html";
            end
            [~, order] = sort(sequences, "descend");
            expected = expected(order);

            page = fileread(fullfile(root, "site", "history", "index.html"));
            tokens = regexp(page, 'href="(records/[^"]+\.html)"', ...
                "tokens");
            actual = strings(numel(tokens), 1);
            for k = 1:numel(tokens)
                actual(k) = string(tokens{k}{1});
            end
            testCase.verifyEqual(actual, expected, ...
                "Generated history must follow sequence rather than title order.");
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
                contains(frameworkPage, "ui-explicit-contract-migration"));
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
