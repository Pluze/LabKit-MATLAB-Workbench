function test_sessionUtilities()
%TEST_SESSIONUTILITIES Verify shared session and summary helpers.

    session = gamrywb.data.makeSession('eis', struct('notes', 'demo notes'));
    assert(strcmp(session.type, 'gamrywb_session'), 'Session type should be stable.');
    assert(strcmp(session.kind, 'eis'), 'Session kind should be preserved.');
    assert(strcmp(session.notes, 'demo notes'), 'Session notes should be preserved.');
    assert(isempty(session.items), 'New session should start with no items.');

    files = {'/tmp/a.DTA', '/tmp/b.DTA', '/tmp/bad.DTA'};
    events = {};
    callbacks = struct();
    callbacks.onAdded = @(filepath, item) recordEvent('added', filepath, item.name);
    callbacks.onSkipped = @(filepath) recordEvent('skipped', filepath, '');
    callbacks.onFailed = @(filepath, message) recordEvent('failed', filepath, message);

    [session, report] = gamrywb.data.addFilesToSession(session, files, @loader, callbacks);
    assert(numel(session.items) == 2, 'Two files should load successfully.');
    assert(isequal(report.added, files(1:2)), 'Added report should preserve load order.');
    assert(isempty(report.skipped), 'No duplicates should be skipped on first add.');
    assert(numel(report.failed) == 1, 'One file should fail through the loader.');
    assert(strcmp(report.failed(1).filepath, '/tmp/bad.DTA'), 'Failed report should preserve filepath.');
    assert(isequal(events(:,1).', {'added', 'added', 'failed'}), ...
        'Session add callbacks should preserve load-order event reporting.');

    [session, report2] = gamrywb.data.addFilesToSession(session, {'/tmp/a.DTA'}, @loader, callbacks);
    assert(numel(session.items) == 2, 'Duplicate add should not change item count.');
    assert(isempty(report2.added), 'Duplicate add should not report added files.');
    assert(isequal(report2.skipped, {'/tmp/a.DTA'}), 'Duplicate add should report skipped filepath.');
    assert(strcmp(events{end, 1}, 'skipped'), 'Session add callback should report skipped duplicates.');

    T = gamrywb.analysis.summarizeBatchResults(session.items);
    assert(isequal(T.Properties.VariableNames, {'Name', 'Filepath', 'Ok', 'Message'}), ...
        'Summary columns should be stable.');
    assert(isequal(T.Name, {'a.DTA'; 'b.DTA'}), 'Summary names should use item names.');
    assert(isequal(T.Ok, [true; false]), 'Summary Ok column should reflect analysis.ok.');
    assert(isequal(T.Message, {'OK'; 'Check'}), 'Summary messages should reflect analysis.message.');

    [session, removeReport] = gamrywb.data.removeFilesFromSession(session, {'b.DTA', 'missing.DTA'});
    assert(numel(session.items) == 1, 'Remove should drop matching item by name.');
    assert(isequal(removeReport.removed, {'/tmp/b.DTA'}), 'Remove report should prefer filepath labels.');
    assert(isequal(removeReport.missing, {'missing.DTA'}), 'Remove report should preserve missing selectors.');

    tmp = [tempname '.mat'];
    cleaner = onCleanup(@() deleteIfExists(tmp));
    gamrywb.io.saveSession(session, tmp);
    loaded = gamrywb.io.loadSession(tmp);
    assert(strcmp(loaded.type, 'gamrywb_session'), 'Loaded session type should be preserved.');
    assert(strcmp(loaded.kind, session.kind), 'Loaded session kind should be preserved.');
    assert(numel(loaded.items) == 1 && strcmp(loaded.items(1).name, 'a.DTA'), ...
        'Loaded session items should be preserved.');

    function recordEvent(kind, filepath, detail)
        events(end+1, :) = {kind, filepath, detail}; %#ok<AGROW>
    end
end

function item = loader(filepath)
    if contains(filepath, 'bad')
        error('loader:badFile', 'Synthetic load failure.');
    end

    [~, name, ext] = fileparts(filepath);
    item = struct();
    item.filepath = filepath;
    item.name = [name ext];
    item.analysis = struct();
    item.analysis.ok = strcmp(name, 'a');
    if item.analysis.ok
        item.analysis.message = 'OK';
    else
        item.analysis.message = 'Check';
    end
end

function deleteIfExists(filepath)
    if exist(filepath, 'file') == 2
        delete(filepath);
    end
end
