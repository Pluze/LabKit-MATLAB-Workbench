function results = run_all_tests(includeGui, selection)
%RUN_ALL_TESTS Run the current MATLAB test suite.

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

    groups = filterGroups(testGroups(includeGui), selection);
    assert(~isempty(groups), 'No test groups matched the requested selection.');
    results = struct('group', {}, 'name', {}, 'passed', {}, 'message', {});

    for g = 1:numel(groups)
        fprintf('\n[%s]\n', groups(g).name);
        tests = groups(g).tests;
        for k = 1:numel(tests)
            name = func2str(tests{k});
            try
                tests{k}();
                results(end+1) = struct( ...
                    'group', groups(g).name, ...
                    'name', name, ...
                    'passed', true, ...
                    'message', ''); %#ok<AGROW>
                fprintf('PASS %s\n', name);
            catch ME
                results(end+1) = struct( ...
                    'group', groups(g).name, ...
                    'name', name, ...
                    'passed', false, ...
                    'message', ME.message); %#ok<AGROW>
                fprintf(2, 'FAIL %s: %s\n', name, ME.message);
            end
        end
    end

    if any(~[results.passed])
        error('One or more tests failed.');
    end
end

function groups = testGroups(includeGui)
    groups = [coreTests(), dtaTests(), biosignalTests(), appTests()];
    if includeGui
        groups = [groups, guiTests()];
    end
end

function group = coreTests()
    group = makeGroup('core', 'core boundaries', { ...
        @test_startup_boundaries, ...
        @test_architecture_boundaries});
end

function group = dtaTests()
    group = makeGroup('dta', 'DTA facade and schemas', { ...
        @test_parseChronoDTA, ...
        @test_parseEISDTA, ...
        @test_parseCVCTDTA, ...
        @test_dtaFacade, ...
        @test_dtaSessionFacade, ...
        @test_detectPulses, ...
        @test_makeChronoItem, ...
        @test_sessionUtilities});
end

function group = biosignalTests()
    group = makeGroup('biosignal', 'biosignal facade and processing', { ...
        @test_biosignalFacade});
end

function group = appTests()
    group = makeGroup('apps', 'app analysis and exports', { ...
        @test_chronoOverlayExport, ...
        @test_computeVTResistance, ...
        @test_vtResistanceExport, ...
        @test_computeCIC, ...
        @test_cicExport, ...
        @test_computeCSC, ...
        @test_plotXY, ...
        @test_eisOverlayExport, ...
        @test_imageCurvatureMeasurement});
end

function group = guiTests()
    group = makeGroup('gui', 'GUI launch and layout', { ...
        @test_gui_smoke, ...
        @test_gui_layout_electrochem, ...
        @test_gui_layout_dic, ...
        @test_gui_layout_image_measurement, ...
        @test_gui_layout_wearable, ...
        @test_gui_layout_ui_helpers});
end

function groups = filterGroups(groups, selection)
    suiteFilter = normalizedCellField(selection, 'suites');
    testFilter = normalizedCellField(selection, 'tests');

    if ~isempty(suiteFilter)
        keep = false(size(groups));
        for k = 1:numel(groups)
            keep(k) = any(strcmp(suiteFilter, lower(groups(k).key))) || ...
                any(strcmp(suiteFilter, lower(groups(k).name)));
        end
        groups = groups(keep);
    end

    if ~isempty(testFilter)
        matchedCount = 0;
        keepGroup = false(size(groups));
        for g = 1:numel(groups)
            tests = groups(g).tests;
            keepTest = false(size(tests));
            for k = 1:numel(tests)
                keepTest(k) = any(strcmp(testFilter, lower(func2str(tests{k}))));
            end
            groups(g).tests = tests(keepTest);
            keepGroup(g) = any(keepTest);
            matchedCount = matchedCount + nnz(keepTest);
        end
        groups = groups(keepGroup);
        assert(matchedCount > 0, 'No tests matched the requested --test selection.');
    end
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

function group = makeGroup(key, name, tests)
    group = struct('key', key, 'name', name, 'tests', {tests});
end
