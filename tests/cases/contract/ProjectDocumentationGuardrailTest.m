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
                            " -> " + forbidden(iWord);
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
            testCase.verifyGreaterThanOrEqual(numel(canonicalTasks), 5, ...
                'docs/testing.md should remain the canonical build-task matrix.');

            files = collectGuidanceFilesExceptTesting(root);
            duplicates = strings(1, 0);
            for k = 1:numel(files)
                tasks = extractBuildtoolTaskNames(fileread(files(k)));
                if numel(tasks) > 1
                    duplicates(end+1) = relativePath(root, files(k)) + ...
                        " -> " + strjoin(tasks, " ");
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
                    missing(end+1) = string(relativePath(root, publicFiles(k)));
                end
            end

            testCase.verifyTrue(isempty(missing), ...
                ['Public +labkit functions need app-facing contract comments immediately ' ...
                'after the function declaration: ' strjoin(cellstr(missing), ', ')]);
        end

        function privateHelperContractDebtIsRemoved(testCase)
            root = setupLabKitTestPath();
            actual = collectPrivateContractDebt(root);
            testCase.verifyTrue(isempty(actual), ...
                ['private helpers without implementation contracts must not remain: ' ...
                strjoin(cellstr(actual), ', ')]);

            fprintf('Private helper contract debt inventory: %d files missing top-of-file contracts.\n', ...
                numel(actual));
        end

        function appOwnedPackageHelpersDocumentImplementationContracts(testCase)
            root = setupLabKitTestPath();
            files = collectAppOwnedPackageFiles(root);
            testCase.assertFalse(isempty(files), ...
                'App-owned package contract guardrail should scan package helper files.');

            missing = strings(1, 0);
            for k = 1:numel(files)
                if ~hasTopFileContract(files(k))
                    missing(end+1) = string(relativePath(root, files(k)));
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
        files(end+1) = string(fullfile(entries(k).folder, entries(k).name));
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
        files(end+1) = filepath;
    end

    skillEntries = dir(fullfile(root, ".agents", "skills", "*", "SKILL.md"));
    for k = 1:numel(skillEntries)
        files(end+1) = string(fullfile(skillEntries(k).folder, skillEntries(k).name));
    end
end

function tasks = extractBuildtoolTaskNames(content)
    tokens = regexp(char(content), ...
        'buildtool[ \t]+([A-Za-z][A-Za-z0-9_]*(?:[ \t]+[A-Za-z][A-Za-z0-9_]*)*)', ...
        'tokens');
    tasks = strings(1, 0);
    for k = 1:numel(tokens)
        tasks = [tasks, split(string(tokens{k}{1})).'];
    end
    tasks = unique(tasks(strlength(tasks) > 0), 'stable');
end

function files = collectPublicLibraryFiles(root)
    allFiles = dir(fullfile(root, '+labkit', '**', '*.m'));
    files = strings(1, 0);
    for k = 1:numel(allFiles)
        filepath = fullfile(allFiles(k).folder, allFiles(k).name);
        if ~contains(filepath, [filesep 'private' filesep])
            files(end+1) = string(filepath);
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
    actual = strings(1, 0);
    for k = 1:numel(privateDirs)
        folder = privateDirs(k);
        if ~isTrackedPrivateScope(root, folder)
            continue;
        end
        files = dir(fullfile(char(folder), '*.m'));
        for f = 1:numel(files)
            filepath = fullfile(files(f).folder, files(f).name);
            if ~hasTopFileContract(filepath)
                actual(end+1) = string(relativePath(root, filepath));
            end
        end
    end
    actual = unique(actual);
end

function files = collectAppOwnedPackageFiles(root)
    entries = dir(fullfile(root, 'apps', '**', '+*', '**', '*.m'));
    files = strings(1, 0);
    for k = 1:numel(entries)
        filepath = string(fullfile(entries(k).folder, entries(k).name));
        if contains(filepath, [filesep 'private' filesep])
            continue;
        end
        files(end+1) = filepath;
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
            folders(end+1) = string(child);
        else
            folders = [folders, collectPrivateDirs(child)];
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
