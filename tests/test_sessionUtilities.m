function test_sessionUtilities()
%TEST_SESSIONUTILITIES Verify session save/load helpers.

    session = gamrywb.dta.makeSession('eis', struct('notes', 'demo notes'));
    assert(strcmp(session.type, 'gamrywb_session'), 'Session type should be stable.');
    assert(strcmp(session.kind, 'eis'), 'Session kind should be preserved.');
    assert(strcmp(session.notes, 'demo notes'), 'Session notes should be preserved.');
    assert(isempty(session.items), 'New session should start with no items.');
    session.items = makeItem('/tmp/a.DTA');

    tmp = [tempname '.mat'];
    cleaner = onCleanup(@() deleteIfExists(tmp));
    gamrywb.dta.saveSession(session, tmp);
    loaded = gamrywb.dta.loadSession(tmp);
    assert(strcmp(loaded.type, 'gamrywb_session'), 'Loaded session type should be preserved.');
    assert(strcmp(loaded.kind, session.kind), 'Loaded session kind should be preserved.');
    assert(numel(loaded.items) == 1 && strcmp(loaded.items(1).name, 'a.DTA'), ...
        'Loaded session items should be preserved.');
end

function item = makeItem(filepath)
    [~, name, ext] = fileparts(filepath);
    item = struct();
    item.filepath = filepath;
    item.name = [name ext];
end

function deleteIfExists(filepath)
    if exist(filepath, 'file') == 2
        delete(filepath);
    end
end
