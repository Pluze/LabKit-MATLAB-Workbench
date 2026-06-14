classdef DtaSessionFacadeTest < matlab.unittest.TestCase
    %DTASESSIONFACADETEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'Unit'})
        function test_dtaSessionFacade(testCase)
            setupLabKitTestPath();
            verify_dtaSessionFacade();
        end
    end
end

function verify_dtaSessionFacade()
%TEST_DTASESSIONFACADE Verify app-facing DTA session helpers.

    fixture = dtaFixturePath('chrono_chronopot_current_pulse_0p2ms.DTA');

    session = labkit.dta.makeSession('template', struct('notes', 'demo'));
    assert(strcmp(session.kind, 'template'), 'DTA facade should create sessions with the requested kind.');
    assert(strcmp(session.notes, 'demo'), 'DTA facade should pass session options through.');

    addedEvents = {};
    callbacks = struct();
    callbacks.onAdded = @(filepath, item) rememberAdded(filepath, item);
    callbacks.onSkipped = @(filepath) rememberSkipped(filepath);

    [session, report] = labkit.dta.addFilesToSession(session, fixture, " Chrono ", callbacks);
    assert(numel(session.items) == 1, 'DTA session facade should add one loaded item.');
    assert(report.nAdded == 1 && report.nSkipped == 0 && report.nFailed == 0, ...
        'DTA session facade should report add/skip/failure counts.');
    assert(session.items(1).type == "chrono", 'DTA session facade should load through expected-kind normalization.');
    assert(numel(addedEvents) == 1 && strcmp(addedEvents{1}, fixture), ...
        'DTA session facade should preserve add callbacks.');

    [session, duplicateReport] = labkit.dta.addFilesToSession(session, fixture, "chrono", callbacks);
    assert(numel(session.items) == 1, 'DTA session facade should not duplicate the same filepath.');
    assert(duplicateReport.nAdded == 0 && duplicateReport.nSkipped == 1 && duplicateReport.nFailed == 0, ...
        'DTA session facade should count duplicate skips.');

    [items, idx] = labkit.dta.selectSessionItems(session, session.items(1).name);
    assert(numel(items) == 1 && idx == 1, 'DTA session facade should select items by display name.');

    removeCallbacks = struct();
    removeCallbacks.onRemoved = @(name, item) rememberRemoved(name, item);
    [session, removeReport] = labkit.dta.removeSelectedItemsFromSession( ...
        session, items(1).name, removeCallbacks);
    assert(isempty(session.items), 'DTA session facade should remove selected session items.');
    assert(numel(removeReport.removed) == 1, 'DTA session facade should preserve remove reports.');

    assertInvalidExpectedKind(@() labkit.dta.addFilesToSession( ...
        labkit.dta.makeSession('template'), {}, "bad"));

    function rememberAdded(filepath, ~)
        addedEvents{end+1} = filepath;
    end

    function rememberSkipped(filepath)
        addedEvents{end+1} = ['skipped:' filepath];
    end

    function rememberRemoved(~, ~)
    end
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
