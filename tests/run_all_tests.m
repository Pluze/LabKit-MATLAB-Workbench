function results = run_all_tests(includeGui)
%RUN_ALL_TESTS Run the current MATLAB test suite.

    if nargin < 1
        includeGui = false;
    end

    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(root);
    addpath(fullfile(root, 'tests'));
    startup_gamrywb();

    tests = {@test_util_functions, @test_phase1_smoke, @test_phase10_apps, @test_parseChronoDTA, @test_parseEISDTA, ...
        @test_parseCVCTDTA, @test_detectPulses, @test_makeChronoItem, @test_chronoOverlayExport, ...
        @test_computeVTResistance, @test_vtResistanceExport, @test_computeCIC, @test_cicExport, @test_computeCSC, @test_plotCVCT, ...
        @test_eisOverlayExport, @test_sessionUtilities};
    if includeGui
        tests{end+1} = @test_gui_smoke;
        tests{end+1} = @test_gui_layout_controls;
    end
    results = struct('name', {}, 'passed', {}, 'message', {});

    for k = 1:numel(tests)
        name = func2str(tests{k});
        try
            tests{k}();
            results(end+1) = struct('name', name, 'passed', true, 'message', ''); %#ok<AGROW>
            fprintf('PASS %s\n', name);
        catch ME
            results(end+1) = struct('name', name, 'passed', false, 'message', ME.message); %#ok<AGROW>
            fprintf(2, 'FAIL %s: %s\n', name, ME.message);
        end
    end

    if any(~[results.passed])
        error('One or more tests failed.');
    end
end
