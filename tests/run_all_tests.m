function results = run_all_tests(includeGui, selection)
%RUN_ALL_TESTS Run the current MATLAB test suite.
%
% Tests live under tests/suites/<target>/test_*.m. Targets mirror source
% ownership: project guardrails, labkit libraries, and app family folders.
% The runner discovers targets recursively and filters by directory name.

    if nargin < 1
        includeGui = false;
    end
    if nargin < 2
        selection = struct();
    end

    root = fileparts(fileparts(mfilename('fullpath')));
    testsRoot = fullfile(root, 'tests');
    addpath(root);
    addpath(genpath(testsRoot));
    startup_labkit();

    results = runLabkitTests(testsRoot, includeGui, selection);
end

function results = runLabkitTests(testsRoot, includeGui, selection)
    suiteRoot = fullfile(testsRoot, 'suites');
    groups = discoverTestGroups(suiteRoot);
    assertUniqueTestNames(groups);

    [groups, guiOnly] = filterGroupsBySuite(groups, selection);
    groups = filterTestsByGuiMode(groups, includeGui, guiOnly);
    groups = filterGroupsByTests(groups, selection);
    groups = removeEmptyGroups(groups);
    assert(~isempty(groups), 'No tests matched the requested selection.');

    results = struct('group', {}, 'name', {}, 'passed', {}, 'message', {}, 'duration_s', {});
    suiteStart = tic;

    for g = 1:numel(groups)
        fprintf('\n[%s]\n', groups(g).key);
        tests = groups(g).tests;
        groupStart = tic;
        for k = 1:numel(tests)
            name = tests(k).name;
            testStart = tic;
            try
                tests(k).handle();
                duration = toc(testStart);
                results(end+1) = struct( ...
                    'group', groups(g).key, ...
                    'name', name, ...
                    'passed', true, ...
                    'message', '', ...
                    'duration_s', duration); %#ok<AGROW>
                fprintf('PASS %s (%.2fs)\n', name, duration);
            catch ME
                duration = toc(testStart);
                results(end+1) = struct( ...
                    'group', groups(g).key, ...
                    'name', name, ...
                    'passed', false, ...
                    'message', ME.message, ...
                    'duration_s', duration); %#ok<AGROW>
                fprintf(2, 'FAIL %s (%.2fs): %s\n', name, duration, ME.message);
            end
        end
        fprintf('[%s completed in %.2fs]\n', groups(g).key, toc(groupStart));
    end

    if any(~[results.passed])
        error('One or more tests failed.');
    end

    fprintf('\nAll selected tests passed in %.2fs.\n', toc(suiteStart));
end

function groups = discoverTestGroups(suiteRoot)
    files = discoverTestFiles(suiteRoot, suiteRoot);
    groups = struct('key', {}, 'tests', {});
    if isempty(files)
        return;
    end

    keys = unique({files.groupKey});
    for g = 1:numel(keys)
        key = keys{g};
        groupFiles = files(strcmp({files.groupKey}, key));
        [~, order] = sort({groupFiles.name});
        groupFiles = groupFiles(order);

        tests = struct('name', {}, 'handle', {}, 'isGui', {});
        for k = 1:numel(groupFiles)
            functionName = groupFiles(k).functionName;
            tests(end+1) = struct( ...
                'name', functionName, ...
                'handle', str2func(functionName), ...
                'isGui', startsWith(functionName, 'test_gui_')); %#ok<AGROW>
        end
        groups(end+1) = struct('key', key, 'tests', {tests}); %#ok<AGROW>
    end
end

function files = discoverTestFiles(folder, suiteRoot)
    files = struct('name', {}, 'functionName', {}, 'groupKey', {});
    entries = dir(folder);
    [~, order] = sort({entries.name});
    entries = entries(order);

    for k = 1:numel(entries)
        entry = entries(k);
        if entry.isdir
            if strcmp(entry.name, '.') || strcmp(entry.name, '..')
                continue;
            end
            childFiles = discoverTestFiles(fullfile(folder, entry.name), suiteRoot);
            files = [files, childFiles]; %#ok<AGROW>
        elseif startsWith(entry.name, 'test_') && endsWith(entry.name, '.m')
            [~, functionName] = fileparts(entry.name);
            files(end+1) = struct( ...
                'name', entry.name, ...
                'functionName', functionName, ...
                'groupKey', suiteGroupKey(folder, suiteRoot)); %#ok<AGROW>
        end
    end
end

function key = suiteGroupKey(folder, suiteRoot)
    if strcmp(folder, suiteRoot)
        key = '.';
        return;
    end
    key = folder(numel(suiteRoot) + 2:end);
    key = strrep(key, filesep, '/');
end

function [groups, guiOnly] = filterGroupsBySuite(groups, selection)
    suiteFilter = normalizedCellField(selection, 'suites');
    guiOnly = any(strcmp(suiteFilter, 'gui'));
    suiteFilter(strcmp(suiteFilter, 'gui')) = [];
    suiteFilter = normalizeSuiteTargets(suiteFilter);

    if isempty(suiteFilter)
        return;
    end

    keep = false(size(groups));
    for g = 1:numel(groups)
        for k = 1:numel(suiteFilter)
            keep(g) = keep(g) || groupMatchesTarget(groups(g).key, suiteFilter{k});
        end
    end
    groups = groups(keep);
end

function targets = normalizeSuiteTargets(targets)
    for k = 1:numel(targets)
        targets{k} = normalizeSuiteTarget(targets{k});
    end
end

function target = normalizeSuiteTarget(target)
    target = strrep(target, '\', '/');
    prefix = 'tests/suites/';
    if startsWith(target, prefix)
        target = target(numel(prefix) + 1:end);
    end
    while startsWith(target, '/')
        target = target(2:end);
    end
    while endsWith(target, '/')
        target = target(1:end-1);
    end

end

function tf = groupMatchesTarget(groupKey, target)
    tf = strcmp(groupKey, target) || startsWith(groupKey, [target '/']);
end

function groups = filterTestsByGuiMode(groups, includeGui, guiOnly)
    for g = 1:numel(groups)
        tests = groups(g).tests;
        if isempty(tests)
            continue;
        end
        if guiOnly
            groups(g).tests = tests([tests.isGui]);
        elseif ~includeGui
            groups(g).tests = tests(~[tests.isGui]);
        end
    end
end

function groups = filterGroupsByTests(groups, selection)
    testFilter = normalizedCellField(selection, 'tests');
    if isempty(testFilter)
        return;
    end

    matchedCount = 0;
    for g = 1:numel(groups)
        tests = groups(g).tests;
        keepTest = false(size(tests));
        for k = 1:numel(tests)
            keepTest(k) = any(strcmp(testFilter, lower(tests(k).name)));
        end
        groups(g).tests = tests(keepTest);
        matchedCount = matchedCount + nnz(keepTest);
    end
    assert(matchedCount > 0, 'No tests matched the requested --test selection.');
end

function groups = removeEmptyGroups(groups)
    keep = false(size(groups));
    for g = 1:numel(groups)
        keep(g) = ~isempty(groups(g).tests);
    end
    groups = groups(keep);
end

function values = normalizedCellField(s, fieldName)
    values = {};
    if ~isfield(s, fieldName)
        return;
    end

    raw = s.(fieldName);
    if isempty(raw)
        return;
    elseif ischar(raw) || isstring(raw)
        values = cellstr(raw);
    elseif iscell(raw)
        values = raw;
    else
        error('Test selection field "%s" must be a string or cell array.', fieldName);
    end
    values = lower(string(values));
    values = cellstr(values(:).');
end

function assertUniqueTestNames(groups)
    names = {};
    for g = 1:numel(groups)
        for k = 1:numel(groups(g).tests)
            names{end+1} = groups(g).tests(k).name; %#ok<AGROW>
        end
    end
    [uniqueNames, ia] = unique(names);
    if numel(uniqueNames) == numel(names)
        return;
    end

    duplicateMask = true(size(names));
    duplicateMask(ia) = false;
    duplicateNames = unique(names(duplicateMask));
    error('Duplicate test function names discovered: %s.', strjoin(duplicateNames, ', '));
end
