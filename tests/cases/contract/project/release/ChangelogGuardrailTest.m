classdef ChangelogGuardrailTest < matlab.unittest.TestCase
    %CHANGELOGGUARDRAILTEST Guard component changelog structure and lookup.

    methods (Test, TestTags = {'Integration', 'Style'})
        function changelogKeepsRequiredSections(testCase)
            root = setupLabKitTestPath();
            changelog = string(fileread(fullfile(root, "CHANGELOG.md")));

            requiredSections = [ ...
                "# LabKit MATLAB Workbench Changelog", ...
                "## How To Use This File", ...
                "## Changelog Model", ...
                "## Structured Change Records", ...
                "## Current Version Lookup" ...
            ];
            for k = 1:numel(requiredSections)
                testCase.verifyTrue(contains(changelog, requiredSections(k)), ...
                    "CHANGELOG.md should keep required section: " + requiredSections(k));
            end

            requiredPhrases = [ ...
                "The primary unit is a user-facing evolution entry", ...
                "Release tags are public anchors", ...
                "Commits and PRs belong in `Evidence`", ...
                "Do not dump raw git logs", ...
                "stable Change ID", ...
                "does not need a separate pending state", ...
                "#### Decision and rationale", ...
                "#### User and data impact", ...
                "#### Known limitations and follow-up" ...
            ];
            for k = 1:numel(requiredPhrases)
                testCase.verifyTrue(contains(changelog, requiredPhrases(k)), ...
                    "CHANGELOG.md should keep maintenance contract phrase: " + ...
                    requiredPhrases(k));
            end

            testCase.verifyFalse(contains(changelog, "## Unreleased") || ...
                contains(changelog, "### Pending"), ...
                "Delivery state belongs to Git and must not split changelog history.");
        end

        function structuredHistoryIsMachineParseable(testCase)
            root = setupLabKitTestPath();
            toolFolder = fullfile(root, "tools", "release");
            addpath(toolFolder);
            cleanup = onCleanup(@() rmpath(toolFolder));

            records = parseLabKitChangelog(fullfile(root, "CHANGELOG.md"));

            testCase.verifyGreaterThanOrEqual(numel(records), 40, ...
                "The normalized baseline should include the complete recorded history.");
            testCase.verifyEqual(numel(unique(string({records.id}))), numel(records));
            testCase.verifyTrue(all(string({records.schema}) == "1"));
            testCase.verifyTrue(all([records.sourceLine] > 0));
            clear cleanup
        end

        function currentLookupMatchesVersionMetadata(testCase)
            root = setupLabKitTestPath();
            changelogLines = splitlines(string(fileread(fullfile(root, "CHANGELOG.md"))));
            records = collectVersionMetadataRecords(root);

            missing = strings(1, 0);
            for k = 1:numel(records)
                record = records(k);
                hasLookupLine = any(contains(changelogLines, "`" + record.path + "`") & ...
                    contains(changelogLines, "`" + record.version + "`"));
                if ~hasLookupLine
                    missing(end+1) = record.path + " " + record.version;
                end
            end

            testCase.verifyTrue(isempty(missing), ...
                ['CHANGELOG.md current lookup should list every versioned metadata ' ...
                'file with its current version: ' strjoin(cellstr(missing), ', ')]);
        end

        function structuredHistoryCoversEveryVersionedComponent(testCase)
            root = setupLabKitTestPath();
            toolFolder = fullfile(root, "tools", "release");
            addpath(toolFolder);
            cleanup = onCleanup(@() rmpath(toolFolder));
            history = parseLabKitChangelog(fullfile(root, "CHANGELOG.md"));
            events = [history.components];
            metadata = collectVersionMetadataRecords(root);

            missing = strings(1, 0);
            for k = 1:numel(metadata)
                record = metadata(k);
                componentEvents = events(string({events.name}) == record.component);
                introductions = componentEvents( ...
                    string({componentEvents.kind}) == "introduced");
                transitions = componentEvents( ...
                    string({componentEvents.kind}) == "transition");
                if numel(introductions) ~= 1
                    missing(end + 1) = record.component + " introduction";
                    continue;
                end
                fromVersions = string({transitions.fromVersion});
                toVersions = [introductions.toVersion, ...
                    string({transitions.toVersion})];
                terminal = toVersions(~ismember(toVersions, fromVersions));
                if numel(terminal) ~= 1 || terminal ~= record.version
                    missing(end + 1) = record.component + " terminal " + ...
                        strjoin(terminal, ",") + " != " + record.version;
                end
            end

            testCase.verifyEmpty(missing, ...
                "Every versioned component needs a continuous history ending at metadata: " + ...
                strjoin(missing, "; "));
            clear cleanup
        end

        function releaseDocsDefineChangelogContract(testCase)
            root = setupLabKitTestPath();
            releaseDoc = string(fileread(fullfile(root, "docs", ...
                "development", "release.md")));
            docsIndex = string(fileread(fullfile(root, "docs", "README.md")));

            requiredReleasePhrases = [ ...
                "`CHANGELOG.md` is the user-facing version map", ...
                "project evolution map", ...
                "one format for current and historical records", ...
                "stable Change ID", ...
                "current version lookup", ...
                "parseLabKitChangelog", ...
                "continuous transition chain", ...
                "decision and rationale", ...
                "When a change bumps `labkit_launcher.m`" ...
            ];
            for k = 1:numel(requiredReleasePhrases)
                testCase.verifyTrue(contains(releaseDoc, requiredReleasePhrases(k)), ...
                    "docs/development/release.md should document changelog maintenance: " + ...
                    requiredReleasePhrases(k));
            end

            testCase.verifyTrue(contains(docsIndex, "Component changelog"), ...
                "docs/README.md should route maintainers to CHANGELOG.md.");
        end
    end
end

function records = collectVersionMetadataRecords(root)
    files = [string(fullfile(root, "labkit_launcher.m")), ...
        collectFiles(fullfile(root, "+labkit"), "version.m"), ...
        collectFiles(fullfile(root, "apps"), "version.m")];
    records = repmat(struct("path", "", "component", "", "version", ""), 1, 0);
    for k = 1:numel(files)
        filepath = files(k);
        rel = string(relativePath(root, filepath));
        version = versionInText(string(fileread(filepath)));
        if strlength(version) == 0
            continue;
        end
        component = componentInText(string(fileread(filepath)), rel);
        records(end+1) = struct( ...
            "path", rel, "component", component, "version", version);
    end
end

function component = componentInText(text, path)
    if path == "labkit_launcher.m"
        component = "labkit_launcher";
        return;
    end
    value = regexp(text, '["'']name["'']\s*,\s*["'']([^"'']+)["'']', ...
        "tokens", "once");
    if isempty(value)
        value = regexp(text, 'versionInfo\(\s*["'']([^"'']+)["'']', ...
            "tokens", "once");
        component = "labkit." + string(value{1});
    else
        component = string(value{1});
    end
end

function files = collectFiles(rootFolder, filename)
    entries = dir(fullfile(rootFolder, "**", filename));
    files = strings(1, 0);
    for k = 1:numel(entries)
        files(end+1) = string(fullfile(entries(k).folder, entries(k).name));
    end
    files = sort(files);
end

function version = versionInText(text)
    version = regexp(text, '["'']version["'']\s*,\s*["'']([^"'']+)["'']', ...
        "tokens", "once");
    if isempty(version)
        version = regexp(text, ...
            'versionInfo\([^,]+,\s*["'']([^"'']+)["'']', ...
            "tokens", "once");
    end
    if isempty(version)
        version = "";
    else
        version = string(version{1});
    end
end

function rel = relativePath(root, filepath)
    rel = string(filepath);
    root = string(root);
    prefix = root + filesep;
    if startsWith(rel, prefix)
        rel = extractAfter(rel, strlength(prefix));
    end
    rel = replace(rel, filesep, "/");
end
