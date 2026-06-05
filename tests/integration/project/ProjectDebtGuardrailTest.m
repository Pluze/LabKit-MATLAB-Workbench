classdef ProjectDebtGuardrailTest < matlab.unittest.TestCase
    %PROJECTDEBTGUARDRAILTEST Expected-debt guardrails for legacy surfaces.

    methods (Test, TestTags = {'Integration', 'Style'})
        function legacyTestBackdoorDebtDoesNotGrow(testCase)
            root = setupLabKitTestPath();

            testCommandFiles = uniqueMatchedFiles(root, {'apps', '+labkit', fullfile('tests', 'suites')}, ...
                '__labkit_test__');
            assertExpectedDebt(testCase, testCommandFiles, 20, ...
                'expected-debt: __labkit_test__ references must not grow before Phase 4 removal');

            handlerFiles = uniqueMatchedFiles(root, {'apps'}, ...
                'function\s+handlers\s*=\s*\w*[Aa]ppTestHandlers');
            assertExpectedDebt(testCase, handlerFiles, 7, ...
                'expected-debt: app test handler functions must not grow before Phase 4 removal');

            diagnosticsFiles = uniqueMatchedFiles(root, {'apps', fullfile('tests', 'suites')}, ...
                'loadFileDiagnostics|parse\w*LoadDiagnosticsRequest|collectLoadDiagnostics');
            assertExpectedDebt(testCase, diagnosticsFiles, 2, ...
                'expected-debt: hidden load diagnostics must not grow before Phase 4 removal');

            fprintf('Legacy backdoor debt inventory: %d __labkit_test__ files, %d handler files, %d diagnostics files.\n', ...
                numel(testCommandFiles), numel(handlerFiles), numel(diagnosticsFiles));
        end

        function oversizedAppEntrypointDebtIsExpected(testCase)
            root = setupLabKitTestPath();
            expectedOversized = sort(string({ ...
                'apps/dic/labkit_DICPostprocess_app.m', ...
                'apps/dic/labkit_DICPreprocess_app.m', ...
                'apps/electrochem/labkit_ChronoOverlay_app.m', ...
                'apps/electrochem/labkit_CIC_app.m', ...
                'apps/electrochem/labkit_CSC_app.m', ...
                'apps/electrochem/labkit_EIS_app.m', ...
                'apps/electrochem/labkit_VTResistance_app.m', ...
                'apps/image_measurement/curvature/labkit_CurvatureMeasurement_app.m', ...
                'apps/image_measurement/focus_stack/labkit_FocusStack_app.m', ...
                'apps/wearable/labkit_ECGPrint_app.m'}));

            actual = collectOversizedEntrypoints(root, 500);
            unexpected = setdiff(sort(actual), expectedOversized);
            testCase.verifyTrue(isempty(unexpected), ...
                ['expected-debt: new app entrypoints over 500 lines before Phase 5: ' ...
                strjoin(cellstr(unexpected), ', ')]);
            testCase.verifyTrue(numel(actual) <= numel(expectedOversized), ...
                sprintf(['expected-debt: oversized app entrypoint count grew from %d to %d; ' ...
                'Phase 5 owns hard-fail removal.'], numel(expectedOversized), numel(actual)));

            fprintf('Entrypoint size debt inventory: %d files over 500 lines.\n', numel(actual));
        end
    end
end

function files = uniqueMatchedFiles(root, scopes, pattern)
    files = strings(1, 0);
    for s = 1:numel(scopes)
        scopeRoot = fullfile(root, scopes{s});
        if ~isfolder(scopeRoot)
            continue;
        end
        textFiles = collectTextFiles(scopeRoot);
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
