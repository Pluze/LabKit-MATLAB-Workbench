classdef ProjectDocumentationGuardrailTest < matlab.unittest.TestCase
    %PROJECTDOCUMENTATIONGUARDRAILTEST Public/private helper comment checks.

    methods (Test, TestTags = {'Integration', 'Style'})
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
                '+labkit/+ui/+view/private', ...
                'apps/image_measurement/curvature/private', ...
                'apps/image_measurement/focus_stack/private'}, ...
                'missingCount', {15, 20, 4, 11, 23, 9, 11});

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
    end
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
