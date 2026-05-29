function results = run_all_tests()
%RUN_ALL_TESTS Run the current MATLAB test suite.

    root = fileparts(fileparts(mfilename('fullpath')));
    addpath(root);
    addpath(fullfile(root, 'tests'));
    startup_gamrywb();

    tests = {@test_util_functions, @test_phase1_smoke, @test_parseChronoDTA, @test_parseEISDTA, ...
        @test_parseCVCTDTA, @test_detectPulses, @test_makeChronoItem, @test_chronoOverlayExport, ...
        @test_computeVTResistance, @test_computeCIC, @test_computeCSC, @test_plotCVCT, ...
        @test_eisOverlayExport};
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
