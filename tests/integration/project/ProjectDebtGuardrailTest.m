classdef ProjectDebtGuardrailTest < matlab.unittest.TestCase
    %PROJECTDEBTGUARDRAILTEST Guardrails for legacy surfaces and expected debt.

    methods (Test, TestTags = {'Integration', 'Style'})
        function legacyTestBackdoorDebtDoesNotGrow(testCase)
            root = setupLabKitTestPath();

            testCommandFiles = uniqueMatchedFiles(root, {'apps', '+labkit'}, ...
                '__labkit_test__');
            testCase.verifyEmpty(testCommandFiles, ...
                ['legacy app test command references must not remain after Phase 4. Files: ' ...
                strjoin(cellstr(testCommandFiles), ', ')]);

            handlerFiles = uniqueMatchedFiles(root, {'apps'}, ...
                'function\s+handlers\s*=\s*\w*[Aa]ppTestHandlers');
            testCase.verifyEmpty(handlerFiles, ...
                ['legacy app test handler functions must not remain after Phase 4. Files: ' ...
                strjoin(cellstr(handlerFiles), ', ')]);

            diagnosticsFiles = uniqueMatchedFiles(root, {'apps'}, ...
                'loadFileDiagnostics|parse\w*LoadDiagnosticsRequest|collectLoadDiagnostics');
            testCase.verifyEmpty(diagnosticsFiles, ...
                ['hidden load diagnostics must not remain after Phase 4. Files: ' ...
                strjoin(cellstr(diagnosticsFiles), ', ')]);

            fprintf('Legacy backdoor inventory: %d test-command files, %d handler files, %d diagnostics files.\n', ...
                numel(testCommandFiles), numel(handlerFiles), numel(diagnosticsFiles));
        end

        function oversizedAppEntrypointDebtIsRemoved(testCase)
            root = setupLabKitTestPath();
            actual = collectOversizedEntrypoints(root, 500);
            testCase.verifyEmpty(actual, ...
                ['app entrypoints must remain at or below 500 lines after Phase 5. Files: ' ...
                strjoin(cellstr(actual), ', ')]);
            fprintf('Entrypoint size debt inventory: %d files over 500 lines.\n', numel(actual));
        end

        function oldRunnerDependenciesAreRemoved(testCase)
            root = setupLabKitTestPath();

            testCase.verifyFalse(isfolder(fullfile(root, 'tests', 'suites')), ...
                'tests/suites must not remain after Phase 6 official-test migration.');
            testCase.verifyFalse(isfile(fullfile(root, 'tests', 'run_all_tests.m')), ...
                'tests/run_all_tests.m must not remain after Phase 6 official-test migration.');

            dependencyFiles = uniqueMatchedFiles(root, ...
                {'.github', 'scripts', 'docs', 'tests', 'buildfile.m', ...
                'README.md', 'AGENTS.md', 'apps', '+labkit'}, ...
                'IncludeLegacy|run_all_tests|tests[/\\]suites');
            dependencyFiles = setdiff(dependencyFiles, ...
                "tests/integration/project/ProjectDebtGuardrailTest.m");
            testCase.verifyEmpty(dependencyFiles, ...
                ['old custom-runner dependencies must not remain after Phase 6. Files: ' ...
                strjoin(cellstr(dependencyFiles), ', ')]);

            fprintf('Old runner dependency inventory: %d files.\n', numel(dependencyFiles));
        end
    end
end

function files = uniqueMatchedFiles(root, scopes, pattern)
    files = strings(1, 0);
    for s = 1:numel(scopes)
        scopeRoot = fullfile(root, scopes{s});
        if isfile(scopeRoot)
            textFiles = {scopeRoot};
        elseif isfolder(scopeRoot)
            textFiles = collectTextFiles(scopeRoot);
        else
            continue;
        end
        for k = 1:numel(textFiles)
            content = fileread(textFiles{k});
            if ~isempty(regexp(content, pattern, 'once'))
                files(end+1) = string(relativePath(root, textFiles{k})); %#ok<AGROW>
            end
        end
    end
    files = unique(files);
end

function files = collectTextFiles(folder)
    files = {};
    entries = dir(folder);
    [~, order] = sort({entries.name});
    entries = entries(order);
    for k = 1:numel(entries)
        entry = entries(k);
        if entry.isdir
            if any(strcmp(entry.name, {'.', '..'}))
                continue;
            end
            files = [files, collectTextFiles(fullfile(folder, entry.name))]; %#ok<AGROW>
        elseif endsWith(entry.name, {'.m', '.md', '.ps1', '.sh', '.yml', '.yaml'})
            files{end+1} = fullfile(entry.folder, entry.name); %#ok<AGROW>
        end
    end
end

function assertExpectedDebt(testCase, actualFiles, expectedMax, label)
    testCase.verifyTrue(numel(actualFiles) <= expectedMax, ...
        sprintf('%s. Current count %d exceeds expected debt %d. Files: %s', ...
        label, numel(actualFiles), expectedMax, strjoin(cellstr(actualFiles), ', ')));
end

function actual = collectOversizedEntrypoints(root, maxLines)
    appFiles = dir(fullfile(root, 'apps', '**', 'labkit_*_app.m'));
    actual = strings(1, 0);
    for k = 1:numel(appFiles)
        filepath = fullfile(appFiles(k).folder, appFiles(k).name);
        lineCount = countFileLines(filepath);
        if lineCount > maxLines
            actual(end+1) = string(relativePath(root, filepath)); %#ok<AGROW>
        end
    end
end

function n = countFileLines(filepath)
    n = numel(readlines(filepath));
end

function rel = relativePath(root, filepath)
    rel = filepath;
    prefix = [root filesep];
    if startsWith(filepath, prefix)
        rel = filepath(numel(prefix)+1:end);
    end
    rel = strrep(rel, filesep, '/');
end
