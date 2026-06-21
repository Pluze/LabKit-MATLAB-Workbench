classdef RepositoryHygieneGuardrailTest < matlab.unittest.TestCase
    %REPOSITORYHYGIENEGUARDRAILTEST Generic repository size and helper hygiene.

    methods (Test, TestTags = {'Integration', 'Style'})
        function trackedFilesStayWithinLineBudget(testCase)
            root = setupLabKitTestPath();
            maxLines = 650;
            actual = collectOversizedTrackedFiles(root, maxLines);
            testCase.verifyEmpty(actual, ...
                ['tracked files must remain at or below ' num2str(maxLines) ...
                ' lines. Split large files by cohesive private helpers or ' ...
                'app-owned component packages before adding more logic. Files: ' ...
                strjoin(cellstr(actual), ', ')]);
        end

        function launcherIsTheOnlyLineBudgetException(testCase)
            root = setupLabKitTestPath();
            maxLines = 650;
            tracked = gitTrackedFiles(root);
            launcher = "labkit_launcher.m";
            tracked = setdiff(tracked, launcher);
            actual = collectOversizedFiles(root, tracked, maxLines);
            testCase.verifyEmpty(actual, ...
                ['only labkit_launcher.m may exceed ' num2str(maxLines) ...
                ' lines because it is the self-contained repair entry point. Files: ' ...
                strjoin(cellstr(actual), ', ')]);
        end

        function scriptsDoNotContainMatlabEntryScripts(testCase)
            root = setupLabKitTestPath();
            actual = collectRelativeFiles(root, fullfile(root, 'scripts', '*.m'));
            testCase.verifyEmpty(actual, ...
                ['launcher-owned MATLAB helpers must remain inside ' ...
                'labkit_launcher.m. Files: ' strjoin(cellstr(actual), ', ')]);
        end

        function trackedTextFilesUseAsciiOnly(testCase)
            root = setupLabKitTestPath();
            tracked = gitTrackedFiles(root);
            textFiles = tracked(arrayfun(@isTextTrackedFile, tracked));
            actual = collectNonAsciiFiles(root, textFiles);
            testCase.verifyEmpty(actual, ...
                ['tracked text files must remain ASCII-only. Files: ' ...
                strjoin(cellstr(actual), ', ')]);
        end

        function appPrivateHelpersAreNotTracked(testCase)
            root = setupLabKitTestPath();
            actualDirs = collectPrivateDirs(fullfile(root, 'apps'), root);
            testCase.verifyTrue(isempty(actualDirs), ...
                ['app private helper directories are not allowed. Files: ' ...
                strjoin(cellstr(actualDirs), ', ')]);

            actualFiles = collectRelativeFiles(root, ...
                fullfile(root, 'apps', '**', 'private', '*.m'));
            testCase.verifyTrue(isempty(actualFiles), ...
                ['app private helper files must live in app-owned packages. Files: ' ...
                strjoin(cellstr(actualFiles), ', ')]);
        end
    end
end

function files = collectNonAsciiFiles(root, tracked)
    files = strings(1, 0);
    for k = 1:numel(tracked)
        filepath = fullfile(root, char(tracked(k)));
        if exist(filepath, 'file') ~= 2
            continue;
        end
        text = fileread(filepath);
        if any(double(text) > 127)
            files(end+1) = tracked(k);
        end
    end
end

function tf = isTextTrackedFile(filepath)
    [~, name, ext] = fileparts(char(filepath));
    ext = lower(string(ext));
    basename = string(name) + ext;
    textExts = [".m", ".md", ".txt", ".json", ".yml", ".yaml", ...
        ".csv", ".tsv", ".xml", ".html", ".css", ".js", ".sh", ...
        ".ps1", ".gitignore", ".gitattributes"];
    textNames = ["LICENSE", "NOTICE", "AGENTS"];
    tf = ismember(ext, textExts) || ismember(basename, textNames) || ...
        startsWith(basename, ".git");
end

function files = collectOversizedTrackedFiles(root, maxLines)
    tracked = gitTrackedFiles(root);
    tracked = setdiff(tracked, "labkit_launcher.m");
    files = collectOversizedFiles(root, tracked, maxLines);
end

function files = collectOversizedFiles(root, tracked, maxLines)
    files = strings(1, 0);
    for k = 1:numel(tracked)
        filepath = fullfile(root, char(tracked(k)));
        if exist(filepath, 'file') ~= 2
            continue;
        end
        lineCount = countFileLines(filepath);
        if lineCount > maxLines
            files(end+1) = tracked(k) + " (" + string(lineCount) + " lines)";
        end
    end
end

function dirs = collectPrivateDirs(folder, root)
    if ~isfolder(folder)
        dirs = strings(1, 0);
        return;
    end

    entries = dir(fullfile(folder, '**', 'private'));
    entries = entries([entries.isdir]);
    if isempty(entries)
        dirs = strings(1, 0);
        return;
    end

    paths = fullfile({entries.folder}, {entries.name});
    dirs = unique(string(relativePaths(root, paths)));
end

function files = collectRelativeFiles(root, pattern)
    entries = dir(pattern);
    files = strings(numel(entries), 1);
    fileCount = 0;
    for k = 1:numel(entries)
        if ~entries(k).isdir
            fileCount = fileCount + 1;
            files(fileCount) = string(relativePath(root, ...
                fullfile(entries(k).folder, entries(k).name)));
        end
    end
    files = unique(files(1:fileCount));
end

function n = countFileLines(filepath)
    n = numel(readlines(filepath));
end

function files = gitTrackedFiles(root)
    command = sprintf('git -C "%s" ls-files', root);
    [status, output] = system(command);
    assert(status == 0, 'Could not list tracked files with git.');
    files = string(splitlines(strtrim(output))).';
    files = files(strlength(files) > 0);
end

function rel = relativePath(root, filepath)
    rel = filepath;
    prefix = [root filesep];
    if startsWith(filepath, prefix)
        rel = filepath(numel(prefix)+1:end);
    end
    rel = strrep(rel, filesep, '/');
end

function paths = relativePaths(root, filepaths)
    paths = cell(size(filepaths));
    for k = 1:numel(filepaths)
        paths{k} = relativePath(root, filepaths{k});
    end
end
