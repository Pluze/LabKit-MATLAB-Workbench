classdef ChangelogGuardrailTest < matlab.unittest.TestCase
    %CHANGELOGGUARDRAILTEST Guard component changelog structure and inventory.

    methods (Test, TestTags = {'Integration', 'Style'})
        function changelogKeepsRequiredSections(testCase)
            root = setupLabKitTestPath();
            changelog = string(fileread(fullfile(root, "CHANGELOG.md")));

            requiredSections = [ ...
                "# LabKit MATLAB Workbench Changelog", ...
                "## Changelog Policy", ...
                "## Unreleased", ...
                "## Current Version Inventory", ...
                "## Release Tag Index", ...
                "## Notable Pre-Versioned History", ...
                "## Version Bump Ledger", ...
                "## Maintenance Template" ...
            ];
            for k = 1:numel(requiredSections)
                testCase.verifyTrue(contains(changelog, requiredSections(k)), ...
                    "CHANGELOG.md should keep required section: " + requiredSections(k));
            end

            requiredPhrases = [ ...
                "`Unreleased` is the staging area", ...
                "`Version Bump Ledger` is the audited mainline history", ...
                "Do not dump raw git logs", ...
                "Audited against `main`" ...
            ];
            for k = 1:numel(requiredPhrases)
                testCase.verifyTrue(contains(changelog, requiredPhrases(k)), ...
                    "CHANGELOG.md should keep maintenance contract phrase: " + ...
                    requiredPhrases(k));
            end
        end

        function currentInventoryMatchesVersionMetadata(testCase)
            root = setupLabKitTestPath();
            changelogLines = splitlines(string(fileread(fullfile(root, "CHANGELOG.md"))));
            records = collectVersionMetadataRecords(root);

            missing = strings(1, 0);
            for k = 1:numel(records)
                record = records(k);
                hasInventoryLine = any(contains(changelogLines, "`" + record.path + "`") & ...
                    contains(changelogLines, "`" + record.version + "`"));
                if ~hasInventoryLine
                    missing(end+1) = record.path + " " + record.version;
                end
            end

            testCase.verifyTrue(isempty(missing), ...
                ['CHANGELOG.md current inventory should list every versioned metadata ' ...
                'file with its current version: ' strjoin(cellstr(missing), ', ')]);
        end

        function releaseDocsDefineChangelogContract(testCase)
            root = setupLabKitTestPath();
            releaseDoc = string(fileread(fullfile(root, "docs", "release.md")));
            docsIndex = string(fileread(fullfile(root, "docs", "README.md")));

            requiredReleasePhrases = [ ...
                "`CHANGELOG.md` is the component version ledger", ...
                "top `Unreleased` section", ...
                "current version inventory", ...
                "audited version bump ledger", ...
                "When a change bumps `labkit_launcher.m`" ...
            ];
            for k = 1:numel(requiredReleasePhrases)
                testCase.verifyTrue(contains(releaseDoc, requiredReleasePhrases(k)), ...
                    "docs/release.md should document changelog maintenance: " + ...
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
    records = repmat(struct("path", "", "version", ""), 1, 0);
    for k = 1:numel(files)
        filepath = files(k);
        rel = string(relativePath(root, filepath));
        version = versionInText(string(fileread(filepath)));
        if strlength(version) == 0
            continue;
        end
        records(end+1) = struct("path", rel, "version", version);
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
