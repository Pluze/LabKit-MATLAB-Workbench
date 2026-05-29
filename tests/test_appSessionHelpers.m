function test_appSessionHelpers()
%TEST_APPSESSIONHELPERS Verify reusable app/session loading helpers.

    session = gamrywb.data.makeSession('overlay');
    events = {};
    callbacks = struct();
    callbacks.onAdded = @(filepath, item) recordEvent('added', filepath, item.name);
    callbacks.onSkipped = @(filepath) recordEvent('skipped', filepath, '');
    callbacks.onFailed = @(filepath, message) recordEvent('failed', filepath, message);

    files = {'/tmp/a.DTA', '/tmp/b.DTA', '/tmp/a.DTA', '/tmp/bad.DTA'};
    [session, report] = gamrywb.ui.loadFilesIntoSession(session, files, @loader, callbacks);
    assert(numel(session.items) == 2, 'Two unique valid files should load.');
    assert(isequal(report.added, {'/tmp/a.DTA', '/tmp/b.DTA'}), 'Added report should preserve first-seen order.');
    assert(isempty(report.skipped), 'Queued duplicates should be collapsed before load callbacks.');
    assert(numel(report.failed) == 1, 'One file should fail through the loader.');
    assert(isequal(events(:,1).', {'added', 'added', 'failed'}), ...
        'Load helper should report added and failed events in load order.');

    [session, report2] = gamrywb.ui.loadFilesIntoSession(session, {'/tmp/a.DTA', '/tmp/c.DTA'}, @loader, callbacks);
    assert(numel(session.items) == 3, 'One new file should be appended after skipping an existing file.');
    assert(isequal(report2.skipped, {'/tmp/a.DTA'}), 'Existing file should be reported as skipped.');
    assert(isequal(report2.added, {'/tmp/c.DTA'}), 'New file should still be added after a skip.');
    assert(isequal(events(end-1:end,1).', {'skipped', 'added'}), ...
        'Existing-file skip should be reported before later new-file add.');

    [session, report3] = gamrywb.ui.loadFilesIntoSession(session, '/tmp/a.DTA', @loader, callbacks);
    assert(numel(session.items) == 3, 'Existing char filepath should not change item count.');
    assert(isempty(report3.added), 'Existing char filepath should not report added files.');
    assert(isequal(report3.skipped, {'/tmp/a.DTA'}), 'Existing char filepath should report a skipped file.');

    removed = {};
    removeCallbacks = struct();
    removeCallbacks.onRemoved = @(name, item) recordRemoved(name, item.filepath);
    [session, removeReport] = gamrywb.ui.removeSelectedItemsFromSession( ...
        session, {'c.DTA', 'a.DTA'}, removeCallbacks);
    assert(numel(session.items) == 1, 'Selected names should be removed from the session.');
    assert(strcmp(session.items(1).name, 'b.DTA'), 'Unselected item should remain.');
    assert(isequal(removed(:,1).', {'a.DTA', 'c.DTA'}), ...
        'Remove callbacks should follow session item order, not selection order.');
    assert(isequal(removeReport.removed, {'/tmp/a.DTA', '/tmp/c.DTA'}), ...
        'Remove report should preserve underlying data helper labels.');

    [session, removeReport2] = gamrywb.ui.removeSelectedItemsFromSession(session, string.empty(0, 1), removeCallbacks);
    assert(numel(session.items) == 1, 'Empty selection should not remove items.');
    assert(isempty(removeReport2.removed), 'Empty selection should not report removed files.');

    [allItems, allIdx] = gamrywb.ui.selectItemsByNames(session.items, {});
    assert(numel(allItems) == 1 && strcmp(allItems(1).name, 'b.DTA'), ...
        'Empty selected-name list should select all remaining items.');
    assert(isequal(allIdx, 1), 'Empty selected-name list should return all item indices.');

    [oneItem, oneIdx] = gamrywb.ui.selectItemsByNames(session.items, "b.DTA");
    assert(numel(oneItem) == 1 && strcmp(oneItem(1).name, 'b.DTA'), ...
        'Matching selected name should return that item.');
    assert(isequal(oneIdx, 1), 'Matching selected name should return matching index.');

    [noItems, noIdx] = gamrywb.ui.selectItemsByNames(session.items, "missing.DTA");
    assert(isempty(noItems), 'Missing selected name should return no items.');
    assert(isempty(noIdx), 'Missing selected name should return no indices.');

    events = {};
    selectionCallbacks = struct();
    selectionCallbacks.restoreDefaultPlotSelections = @() recordSelectionEvent('restore');
    selectionCallbacks.resetAxesToDefaultState = @() recordSelectionEvent('reset');
    selectionCallbacks.refreshResultsSummary = @() recordSelectionEvent('summary');
    selectionCallbacks.refreshPlots = @() recordSelectionEvent('plots');

    lb = struct('Items', {{'a.DTA', 'b.DTA'}}, 'Value', 'b.DTA');
    selectedIdx = gamrywb.ui.handleSingleFileSelection(lb, selectionCallbacks);
    assert(selectedIdx == 2, 'Single-file selection helper should return the selected listbox index.');
    assert(isequal(events.', {'restore', 'reset', 'summary', 'plots'}), ...
        'Single-file selection helper should preserve the nonempty callback order.');

    events = {};
    lb = struct('Items', {{}}, 'Value', {{}});
    selectedIdx = gamrywb.ui.handleSingleFileSelection(lb, selectionCallbacks);
    assert(isempty(selectedIdx), 'Single-file selection helper should clear current index for empty lists.');
    assert(isequal(events.', {'reset', 'summary', 'plots'}), ...
        'Single-file selection helper should preserve the empty-list callback order.');

    events = {};
    appliedState = struct();
    clearCallbacks = struct();
    clearCallbacks.applyState = @recordAppliedState;
    clearCallbacks.restoreDefaultPlotSelections = @() recordSelectionEvent('restore');
    clearCallbacks.resetAxesToDefaultState = @() recordSelectionEvent('reset');
    clearCallbacks.refreshFileList = @() recordSelectionEvent('files');
    clearCallbacks.refreshBatchTable = @() recordSelectionEvent('table');
    clearCallbacks.refreshResultsSummary = @() recordSelectionEvent('summary');
    clearCallbacks.refreshPlots = @() recordSelectionEvent('plots');
    clearCallbacks.addLog = @(msg) recordSelectionEvent(['log:' msg]);
    clearState = gamrywb.ui.handleClearSingleFileSession('cic_vt', clearCallbacks);
    assert(strcmp(clearState.session.kind, 'cic_vt'), ...
        'Clear helper should create a replacement session with the requested kind.');
    assert(isempty(clearState.items) && isempty(clearState.current), ...
        'Clear helper should return empty items and current selection.');
    assert(strcmp(appliedState.session.kind, 'cic_vt') && isempty(appliedState.items) && isempty(appliedState.current), ...
        'Clear helper should apply the replacement state before refreshing UI callbacks.');
    assert(isequal(events.', {'apply', 'restore', 'reset', 'files', 'table', 'summary', 'plots', 'log:Cleared all files.'}), ...
        'Clear helper should preserve the clear-all callback order.');

    function recordEvent(kind, filepath, detail)
        events(end+1, :) = {kind, filepath, detail}; %#ok<AGROW>
    end

    function recordRemoved(name, filepath)
        removed(end+1, :) = {name, filepath}; %#ok<AGROW>
    end

    function recordSelectionEvent(kind)
        events{end+1, 1} = kind; %#ok<AGROW>
    end

    function recordAppliedState(sessionArg, itemsArg, currentArg)
        appliedState.session = sessionArg;
        appliedState.items = itemsArg;
        appliedState.current = currentArg;
        recordSelectionEvent('apply');
    end
end

function item = loader(filepath)
    if contains(filepath, 'bad')
        error('loader:badFile', 'Synthetic load failure.');
    end

    item = struct();
    item.filepath = filepath;
    item.name = gamrywb.util.shortName(filepath);
end
