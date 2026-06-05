classdef ProjectDocumentationGuardrailTest < matlab.unittest.TestCase
    %PROJECTDOCUMENTATIONGUARDRAILTEST Documentation ownership and contract checks.

    methods (Test, TestTags = {'Integration', 'Style'})
        function humanDocsDoNotContainAgentOnlyWorkflowMandates(testCase)
            root = setupLabKitTestPath();
            files = collectHumanDocFiles(root);
            forbidden = [ ...
                "Codex", ...
                "agent-only", ...
                "git handoff", ...
                "dedicated development branch", ...
                "force-push", ...
                "Conventional Commits", ...
                "commit hash", ...
                "branch deletion", ...
                "current turn", ...
                "final response"];

            leaks = strings(1, 0);
            for k = 1:numel(files)
                content = lower(string(fileread(files(k))));
                for iWord = 1:numel(forbidden)
                    if contains(content, lower(forbidden(iWord)))
                        leaks(end+1) = relativePath(root, files(k)) + ...
                            " -> " + forbidden(iWord); %#ok<AGROW>
                    end
                end
            end

            testCase.verifyTrue(isempty(leaks), ...
                ['Human docs should not contain agent-only workflow mandates: ' ...
                strjoin(cellstr(leaks), ', ')]);
        end

        function testingDocOwnsBuildTaskCommandMatrix(testCase)
            root = setupLabKitTestPath();
            canonical = fullfile(root, "docs", "testing.md");
            canonicalTasks = extractBuildtoolTaskNames(fileread(canonical));
            testCase.verifyGreaterThan(numel(canonicalTasks), 5, ...
                'docs/testing.md should remain the canonical build-task matrix.');

            files = collectGuidanceFilesExceptTesting(root);
            duplicates = strings(1, 0);
            for k = 1:numel(files)
                tasks = extractBuildtoolTaskNames(fileread(files(k)));
                if numel(tasks) > 1
                    duplicates(end+1) = relativePath(root, files(k)) + ...
                        " -> " + strjoin(tasks, " "); %#ok<AGROW>
                end
            end

            testCase.verifyTrue(isempty(duplicates), ...
                ['Only docs/testing.md should maintain a build-task command matrix: ' ...
                strjoin(cellstr(duplicates), ', ')]);
        end

        function publicLibraryFunctionsDocumentAppFacingContracts(testCase)
            root = setupLabKitTestPath();
            publicFiles = collectPublicLibraryFiles(root);
            missing = strings(1, 0);
            for k = 1:numel(publicFiles)
                if ~hasFunctionContractComment(publicFiles(k))
                    missing(end+1) = string(relativePath(root, publicFiles(k))); %#ok<AGROW>
                end
            end

            testCase.verifyTrue(isempty(missing), ...
                ['Public +labkit functions need app-facing contract comments immediately ' ...
                'after the function declaration: ' strjoin(cellstr(missing), ', ')]);
        end

        function privateHelperContractDebtDoesNotGrow(testCase)
            root = setupLabKitTestPath();
            expectedDebt = struct( ...
                'folder', { ...
                '+labkit/+biosignal/private', ...
                '+labkit/+dta/private', ...
                '+labkit/+ui/+app/private', ...
                '+labkit/+ui/+tool/private', ...
                '+labkit/+ui/+view/private'}, ...
                'missingCount', {15, 20, 4, 11, 23});

            actual = collectPrivateContractDebt(root);
            expectedFolders = sort(string({expectedDebt.folder}));
            actualFolders = sort(string({actual.folder}));
            unexpectedFolders = setdiff(actualFolders, expectedFolders);
            testCase.verifyTrue(isempty(unexpectedFolders), ...
                ['expected-debt: new private-helper folders without implementation contracts: ' ...
                strjoin(cellstr(unexpectedFolders), ', ')]);

            for k = 1:numel(expectedDebt)
                folder = expectedDebt(k).folder;
                idx = find(actualFolders == string(folder), 1);
                actualCount = 0;
                if ~isempty(idx)
                    actualCount = actual(idx).missingCount;
                end
                testCase.verifyTrue(actualCount <= expectedDebt(k).missingCount, ...
                    sprintf(['expected-debt: private helper implementation contract debt grew in %s. ' ...
                    'Current %d, expected <= %d.'], folder, actualCount, expectedDebt(k).missingCount));
            end

            totalMissing = sum([actual.missingCount]);
            fprintf('Private helper contract debt inventory: %d files missing top-of-file contracts.\n', ...
                totalMissing);
        end

        function appOwnedPackageHelpersDocumentImplementationContracts(testCase)
            root = setupLabKitTestPath();
            files = collectAppOwnedPackageFiles(root);
            testCase.assertFalse(isempty(files), ...
                'App-owned package contract guardrail should scan package helper files.');

            missing = strings(1, 0);
            for k = 1:numel(files)
                if ~hasTopFileContract(files(k))
                    missing(end+1) = string(relativePath(root, files(k))); %#ok<AGROW>
                end
            end

            testCase.verifyTrue(isempty(missing), ...
                ['App-owned package helpers need top-of-file implementation contracts: ' ...
                strjoin(cellstr(missing), ', ')]);
        end
    end
end

function files = collectHumanDocFiles(root)
    files = string(fullfile(root, "README.md"));
    entries = dir(fullfile(root, "docs", "*.md"));
    for k = 1:numel(entries)
        files(end+1) = string(fullfile(entries(k).folder, entries(k).name)); %#ok<AGROW>
    end
end

function files = collectGuidanceFilesExceptTesting(root)
    files = [ ...
        string(fullfile(root, "README.md")), ...
        string(fullfile(root, "AGENTS.md")), ...
        string(fullfile(root, "apps", "AGENTS.md")), ...
        string(fullfile(root, "tests", "AGENTS.md")), ...
        string(fullfile(root, "+labkit", "AGENTS.md"))];

    docEntries = dir(fullfile(root, "docs", "*.md"));
    for k = 1:numel(docEntries)
        filepath = string(fullfile(docEntries(k).folder, docEntries(k).name));
        if endsWith(filepath, fullfile("docs", "testing.md"))
            continue;
        end
        files(end+1) = filepath; %#ok<AGROW>
    end

    skillEntries = dir(fullfile(root, ".agents", "skills", "*", "SKILL.md"));
    for k = 1:numel(skillEntries)
        files(end+1) = string(fullfile(skillEntries(k).folder, skillEntries(k).name)); %#ok<AGROW>
    end
end

function tasks = extractBuildtoolTaskNames(content)
    tokens = regexp(char(content), ...
        'buildtool[ \t]+([A-Za-z][A-Za-z0-9_]*(?:[ \t]+[A-Za-z][A-Za-z0-9_]*)*)', ...
        'tokens');
    tasks = strings(1, 0);
    for k = 1:numel(tokens)
        tasks = [tasks, split(string(tokens{k}{1})).']; %#ok<AGROW>
    end
    tasks = unique(tasks(strlength(tasks) > 0), 'stable');
end

function files = collectPublicLibraryFiles(root)
    allFiles = dir(fullfile(root, '+labkit', '**', '*.m'));
    files = strings(1, 0);
    for k = 1:numel(allFiles)
        filepath = fullfile(allFiles(k).folder, allFiles(k).name);
        if ~contains(filepath, [filesep 'private' filesep])
            files(end+1) = string(filepath); %#ok<AGROW>
        end
    end
end

function tf = hasFunctionContractComment(filepath)
    lines = readlines(filepath);
    idx = find(startsWith(strtrim(lines), "function "), 1);
    if isempty(idx)
        tf = false;
        return;
    end
    nextIdx = idx + 1;
    while nextIdx <= numel(lines) && strlength(strtrim(lines(nextIdx))) == 0
        nextIdx = nextIdx + 1;
    end
    tf = nextIdx <= numel(lines) && startsWith(strtrim(lines(nextIdx)), "%");
end

function actual = collectPrivateContractDebt(root)
    privateDirs = [ ...
        collectPrivateDirs(fullfile(root, '+labkit')), ...
        collectPrivateDirs(fullfile(root, 'apps'))];
    actual = struct('folder', {}, 'missingCount', {});
    for k = 1:numel(privateDirs)
        folder = privateDirs(k);
        if ~isTrackedPrivateScope(root, folder)
            continue;
        end
        files = dir(fullfile(char(folder), '*.m'));
        missing = 0;
        for f = 1:numel(files)
            filepath = fullfile(files(f).folder, files(f).name);
            if ~hasTopFileContract(filepath)
                missing = missing + 1;
            end
        end
        if missing > 0
            actual(end+1) = struct( ... %#ok<AGROW>
                'folder', relativePath(root, folder), ...
                'missingCount', missing);
        end
    end
end

function files = collectAppOwnedPackageFiles(root)
    entries = dir(fullfile(root, 'apps', '**', '+*', '**', '*.m'));
    files = strings(1, 0);
    for k = 1:numel(entries)
        filepath = string(fullfile(entries(k).folder, entries(k).name));
        if contains(filepath, [filesep 'private' filesep])
            continue;
        end
        files(end+1) = filepath; %#ok<AGROW>
    end
    files = unique(files);
end

function folders = collectPrivateDirs(folder)
    folders = strings(1, 0);
    if ~isfolder(folder)
        return;
    end
    entries = dir(folder);
    [~, order] = sort({entries.name});
    entries = entries(order);
    for k = 1:numel(entries)
        entry = entries(k);
        if ~entry.isdir || any(strcmp(entry.name, {'.', '..'}))
            continue;
        end
        child = fullfile(entry.folder, entry.name);
        if strcmp(entry.name, 'private')
            folders(end+1) = string(child); %#ok<AGROW>
        else
            folders = [folders, collectPrivateDirs(child)]; %#ok<AGROW>
        end
    end
end

function tf = isTrackedPrivateScope(root, folder)
    rel = string(relativePath(root, folder));
    tf = startsWith(rel, "+labkit/") || startsWith(rel, "apps/");
end

function tf = hasTopFileContract(filepath)
    lines = readlines(filepath);
    first = strings(0);
    for k = 1:numel(lines)
        if strlength(strtrim(lines(k))) > 0
            first = strtrim(lines(k));
            break;
        end
    end
    tf = ~isempty(first) && startsWith(first, "%");
end

function rel = relativePath(root, filepath)
    rel = char(filepath);
    prefix = [root filesep];
    if startsWith(rel, prefix)
        rel = rel(numel(prefix)+1:end);
    end
    rel = strrep(rel, filesep, '/');
end
