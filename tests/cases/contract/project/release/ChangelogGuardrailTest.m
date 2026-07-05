classdef ChangelogGuardrailTest < matlab.unittest.TestCase
    %CHANGELOGGUARDRAILTEST Guard component changelog structure and lookup.

    methods (Test, TestTags = {'Integration', 'Style'})
        function changelogKeepsRequiredSections(testCase)
            root = setupLabKitTestPath();
            changelog = string(fileread(fullfile(root, "CHANGELOG.md")));

            requiredSections = [ ...
                "# LabKit MATLAB Workbench Changelog", ...
                "## How To Use This File", ...
                "## Unreleased", ...
                "## Current Version Lookup", ...
                "## Version History", ...
                "## Maintenance Template" ...
            ];
            for k = 1:numel(requiredSections)
                testCase.verifyTrue(contains(changelog, requiredSections(k)), ...
                    "CHANGELOG.md should keep required section: " + requiredSections(k));
            end

            requiredPhrases = [ ...
                "`Version History` as the main reading path", ...
                "Do not dump raw git logs", ...
                "Why it matters:", ...
                "Compatibility:", ...
                "Evidence:", ...
                "Audited against `main`" ...
            ];
            for k = 1:numel(requiredPhrases)
                testCase.verifyTrue(contains(changelog, requiredPhrases(k)), ...
                    "CHANGELOG.md should keep maintenance contract phrase: " + ...
                    requiredPhrases(k));
            end
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

        function releaseDocsDefineChangelogContract(testCase)
            root = setupLabKitTestPath();
            releaseDoc = string(fileread(fullfile(root, "docs", "release.md")));
            docsIndex = string(fileread(fullfile(root, "docs", "README.md")));

            requiredReleasePhrases = [ ...
                "`CHANGELOG.md` is the user-facing version map", ...
                "top `Unreleased` section", ...
                "current version lookup", ...
                "one `Version History` reading path", ...
                "why it matters", ...
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
