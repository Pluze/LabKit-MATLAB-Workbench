classdef DtaFileInputFacadeTest < matlab.unittest.TestCase
    %DTAFILEINPUTFACADETEST Verify DTA loading accepts filePanel inputs.

    methods (Test, TestTags = {'Unit'})
        function test_dtaFileInputFacade(testCase)
            setupLabKitTestPath();
            verify_dtaFileInputFacade();
        end
    end
end

function verify_dtaFileInputFacade()
%TEST_DTAFILEINPUTFACADE Verify GUI-free DTA loaders accept file path shapes.

    fixture = dtaFixturePath('chrono_chronopot_current_pulse_0p2ms.DTA');
    pathColumn = reshape(string(fixture), [], 1);

    [items, report] = labkit.dta.loadFiles(pathColumn, " Chrono ");
    assert(numel(items) == 1, ...
        'DTA facade should load filePanel string-column paths.');
    assert(report.nRequested == 1 && report.nLoaded == 1 && report.nFailed == 0, ...
        'DTA facade should report string-column file loads clearly.');
    assert(items{1}.type == "chrono", ...
        'DTA facade should normalize expected kind for file inputs.');

    [cellItems, cellReport] = labkit.dta.loadFiles({string(fixture)}, "chrono");
    assert(numel(cellItems) == 1 && cellReport.nLoaded == 1, ...
        'DTA facade should accept scalar-string cell paths from app code.');

    assertInvalidExpectedKind(@() labkit.dta.loadFiles(pathColumn, "bad"));
end

function assertInvalidExpectedKind(fcn)
    try
        fcn();
    catch ME
        assert(strcmp(ME.identifier, 'labkit:dta:InvalidKind'), ...
            'Invalid expected kind should raise labkit:dta:InvalidKind.');
        return;
    end
    error('Expected invalid expected kind to throw.');
end
