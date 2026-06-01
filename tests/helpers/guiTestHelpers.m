function h = guiTestHelpers()
%GUITESTHELPERS Shared noninteractive GUI test assertions and callbacks.

    h = struct();
    h.assertUifigureAvailable = @assertUifigureAvailable;
    h.closeAllFigures = @closeAllFigures;
    h.launchFigure = @launchFigure;
    h.assertButtonContract = @assertButtonContract;
    h.assertCheckboxContract = @assertCheckboxContract;
    h.assertTabTitles = @assertTabTitles;
    h.assertScrollablePanel = @assertScrollablePanel;
    h.assertScrollableGrid = @assertScrollableGrid;
    h.dropdownGroup = @dropdownGroup;
    h.assertDropdownGroups = @assertDropdownGroups;
    h.axesSpec = @axesSpec;
    h.assertAxesContract = @assertAxesContract;
    h.assertAxesPopoutEnabled = @assertAxesPopoutEnabled;
    h.assertAxesChildrenUsePopoutMenu = @assertAxesChildrenUsePopoutMenu;
    h.assertTableColumns = @assertTableColumns;
    h.assertAnyTableColumns = @assertAnyTableColumns;
    h.assertFigureMinimumSize = @assertFigureMinimumSize;
    h.assertComponentCounts = @assertComponentCounts;
    h.findControlsByClass = @findControlsByClass;
    h.assertDropdownCallbacksPresent = @assertDropdownCallbacksPresent;
    h.invokeDropdownValue = @invokeDropdownValue;
    h.invokeCheckbox = @invokeCheckbox;
    h.invokeButton = @invokeButton;
    h.findControlByText = @findControlByText;
    h.invokeCallback = @invokeCallback;
    h.assertCallbackPresent = @assertCallbackPresent;
    h.sameStringCell = @sameStringCell;
end

function fig = launchFigure(entryName, expectedTitle)
    closeAllFigures();
    feval(entryName);
    drawnow;
    figs = findall(groot, 'Type', 'figure');
    names = getFigureNames(figs);
    idx = find(strcmp(names, expectedTitle), 1);
    assert(~isempty(idx), 'GUI entry point %s did not create expected figure "%s".', entryName, expectedTitle);
    fig = figs(idx);
end

function assertTexts(fig, expectedTexts)
    actual = string(getTextValues(fig));
    for k = 1:numel(expectedTexts)
        assert(any(actual == string(expectedTexts{k})), 'Missing GUI text/control: %s', expectedTexts{k});
    end
end

function assertButtonContract(fig, expectedTexts)
    assertTexts(fig, expectedTexts);
    for k = 1:numel(expectedTexts)
        h = findControlByText(fig, expectedTexts{k}, 'ButtonPushedFcn');
        assertCallbackPresent(h, 'ButtonPushedFcn', expectedTexts{k});
    end
end

function assertCheckboxContract(fig, expectedTexts)
    assertTexts(fig, expectedTexts);
end

function assertTabTitles(fig, expectedTitles)
    actual = string(getPropertyValues(fig, 'Title'));
    for k = 1:numel(expectedTitles)
        assert(any(actual == string(expectedTitles{k})), 'Missing GUI tab/panel title: %s', expectedTitles{k});
    end
end

function assertScrollablePanel(panel, label)
    assert(isprop(panel, 'Scrollable'), '%s should expose a Scrollable property.', label);
    assert(strcmp(char(panel.Scrollable), 'on'), '%s should be scrollable.', label);
end

function assertScrollableGrid(grid, label)
    assert(isprop(grid, 'Scrollable'), '%s should expose a Scrollable property.', label);
    assert(strcmp(char(grid.Scrollable), 'on'), '%s should be scrollable.', label);
end

function group = dropdownGroup(items, count)
    group = struct('items', {items}, 'count', count);
end

function assertDropdownGroups(fig, expectedGroups)
    dropdowns = findControlsByClass(fig, 'DropDown');
    for k = 1:numel(expectedGroups)
        expectedItems = expectedGroups(k).items;
        expectedCount = expectedGroups(k).count;
        actualCount = 0;
        for j = 1:numel(dropdowns)
            if sameStringCell(dropdowns{j}.Items, expectedItems)
                actualCount = actualCount + 1;
            end
        end
        assert(actualCount == expectedCount, ...
            'Expected %d dropdown(s) with items [%s], found %d.', ...
            expectedCount, strjoin(expectedItems, ', '), actualCount);
    end
end

function spec = axesSpec(titleText, xLabel, yLabel)
    spec = struct('title', titleText, 'xLabel', xLabel, 'yLabel', yLabel);
end

function assertAxesContract(fig, expectedAxes)
    axesHandles = findControlsByClass(fig, 'Axes');
    assert(numel(axesHandles) == numel(expectedAxes), ...
        'Expected %d axes contract entry/entries, found %d axes.', numel(expectedAxes), numel(axesHandles));
    for k = 1:numel(expectedAxes)
        found = false;
        for j = 1:numel(axesHandles)
            if axesMatches(axesHandles{j}, expectedAxes{k})
                found = true;
                break;
            end
        end
        assert(found, 'Missing axes contract: title="%s", xlabel="%s", ylabel="%s".', ...
            expectedAxes{k}.title, expectedAxes{k}.xLabel, expectedAxes{k}.yLabel);
    end
end

function assertAxesPopoutEnabled(ax, message)
    menu = ax.ContextMenu;
    assert(~isempty(menu) && isvalid(menu), message);
    item = findall(menu, 'Type', 'uimenu', 'Tag', 'labkitAxesPopoutMenu');
    assert(numel(item) == 1, message);
    assert(strcmp(item.Text, 'Open axes in new figure'), message);
end

function assertAxesChildrenUsePopoutMenu(ax, message)
    menu = ax.ContextMenu;
    children = ax.Children;
    assert(~isempty(children), message);
    for k = 1:numel(children)
        if isprop(children(k), 'ContextMenu')
            assert(isequal(children(k).ContextMenu, menu), message);
        end
    end
end

function tf = axesMatches(ax, spec)
    tf = strcmp(char(ax.Title.String), spec.title) && ...
        strcmp(char(ax.XLabel.String), spec.xLabel) && ...
        strcmp(char(ax.YLabel.String), spec.yLabel);
end

function assertTableColumns(fig, expectedColumns)
    tables = findControlsByClass(fig, 'Table');
    assert(numel(tables) == 1, 'Expected exactly one result table, found %d.', numel(tables));
    assert(sameStringCell(tables{1}.ColumnName, expectedColumns), ...
        'Result table columns changed. Expected [%s], found [%s].', ...
        strjoin(expectedColumns, ', '), strjoin(toCellstr(tables{1}.ColumnName), ', '));
end

function assertAnyTableColumns(fig, expectedColumns)
    tables = findControlsByClass(fig, 'Table');
    for k = 1:numel(tables)
        if sameStringCell(tables{k}.ColumnName, expectedColumns)
            return;
        end
    end
    found = cell(1, numel(tables));
    for k = 1:numel(tables)
        found{k} = ['[' strjoin(toCellstr(tables{k}.ColumnName), ', ') ']'];
    end
    assert(false, 'Missing table columns [%s]. Found %s.', ...
        strjoin(expectedColumns, ', '), strjoin(found, '; '));
end

function assertFigureMinimumSize(fig, minWidth, minHeight)
    pos = fig.Position;
    assert(pos(3) >= minWidth, 'Expected figure width >= %d, found %.0f.', minWidth, pos(3));
    assert(pos(4) >= minHeight, 'Expected figure height >= %d, found %.0f.', minHeight, pos(4));
end

function assertComponentCounts(fig, expectedCounts)
    names = fieldnames(expectedCounts);
    for k = 1:numel(names)
        name = names{k};
        expected = expectedCounts.(name);
        actual = countComponents(fig, name);
        assert(actual == expected, 'Expected %d %s component(s), found %d.', expected, name, actual);
    end
end

function count = countComponents(fig, classNamePart)
    controls = allGuiObjects(fig);
    count = 0;
    for k = 1:numel(controls)
        if contains(class(controls{k}), classNamePart)
            count = count + 1;
        end
    end
end

function controls = findControlsByClass(fig, classNamePart)
    allControls = allGuiObjects(fig);
    controls = {};
    for k = 1:numel(allControls)
        if contains(class(allControls{k}), classNamePart)
            controls{end+1} = allControls{k}; %#ok<AGROW>
        end
    end
end

function assertDropdownCallbacksPresent(fig)
    controls = allGuiObjects(fig);
    for k = 1:numel(controls)
        control = controls{k};
        if contains(class(control), 'DropDown') && isprop(control, 'ValueChangedFcn')
            assertCallbackPresent(control, 'ValueChangedFcn', describeControl(control));
        end
    end
end

function invokeDropdownValue(fig, value)
    controls = allGuiObjects(fig);
    for k = 1:numel(controls)
        control = controls{k};
        if isprop(control, 'Items') && isprop(control, 'Value') && any(strcmp(control.Items, value))
            control.Value = value;
            invokeCallback(control, 'ValueChangedFcn');
            drawnow;
            return;
        end
    end
    error('Dropdown value not found: %s', value);
end

function invokeCheckbox(fig, text, value)
    control = findControlByText(fig, text, 'Value');
    control.Value = value;
    invokeCallback(control, 'ValueChangedFcn');
    drawnow;
end

function invokeButton(fig, text)
    control = findControlByText(fig, text, 'ButtonPushedFcn');
    invokeCallback(control, 'ButtonPushedFcn');
    drawnow;
end

function h = findControlByText(fig, text, callbackProperty)
    controls = allGuiObjects(fig);
    for k = 1:numel(controls)
        candidate = controls{k};
        if isprop(candidate, 'Text') && strcmp(char(candidate.Text), text) && isprop(candidate, callbackProperty)
            h = candidate;
            return;
        end
    end
    error('Control not found: %s', text);
end

function invokeCallback(h, callbackProperty)
    cb = h.(callbackProperty);
    if isempty(cb)
        return;
    end
    if isa(cb, 'function_handle')
        cb(h, []);
    elseif iscell(cb) && ~isempty(cb) && isa(cb{1}, 'function_handle')
        cb{1}(h, [], cb{2:end});
    else
        error('Unsupported callback type for %s.', callbackProperty);
    end
end

function assertCallbackPresent(h, callbackProperty, label)
    assert(~isempty(h.(callbackProperty)), 'Missing %s callback for %s.', callbackProperty, label);
end

function label = describeControl(h)
    if isprop(h, 'Text') && ~isempty(h.Text)
        label = char(h.Text);
    elseif isprop(h, 'Items') && ~isempty(h.Items)
        items = h.Items;
        if isstring(items)
            items = cellstr(items);
        end
        label = ['dropdown [' strjoin(items, ', ') ']'];
    else
        label = class(h);
    end
end

function values = getTextValues(fig)
    values = getPropertyValues(fig, 'Text');
end

function values = getPropertyValues(fig, propertyName)
    controls = allGuiObjects(fig);
    values = {};
    for k = 1:numel(controls)
        control = controls{k};
        if isprop(control, propertyName)
            value = control.(propertyName);
            if ischar(value) || isstring(value)
                values{end+1} = char(value); %#ok<AGROW>
            end
        end
    end
end

function tf = sameStringCell(actual, expected)
    actual = reshape(string(toCellstr(actual)), 1, []);
    expected = reshape(string(toCellstr(expected)), 1, []);
    tf = isequal(actual, expected);
end

function values = toCellstr(values)
    if isstring(values)
        values = cellstr(values);
    elseif ischar(values)
        values = {values};
    elseif iscell(values)
        values = cellfun(@char, values, 'UniformOutput', false);
    else
        values = cellstr(string(values));
    end
end

function objects = allGuiObjects(root)
    objects = {root};
    if ~isprop(root, 'Children')
        return;
    end
    children = root.Children;
    for k = 1:numel(children)
        objects = [objects, allGuiObjects(children(k))]; %#ok<AGROW>
    end
end

function assertUifigureAvailable()
    try
        f = uifigure('Visible', 'off', 'Name', 'labkit_gui_layout_probe');
        delete(f);
    catch ME
        error('GUI layout tests require MATLAB uifigure support: %s', ME.message);
    end
end

function names = getFigureNames(figs)
    names = cell(size(figs));
    for i = 1:numel(figs)
        names{i} = figs(i).Name;
    end
end

function closeAllFigures()
    figs = findall(groot, 'Type', 'figure');
    if ~isempty(figs)
        delete(figs);
    end
    drawnow;
end
