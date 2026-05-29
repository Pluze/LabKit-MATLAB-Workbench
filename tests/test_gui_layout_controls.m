function test_gui_layout_controls()
%TEST_GUI_LAYOUT_CONTROLS Verify noninteractive GUI layout and safe callbacks.

    assertUifigureAvailable();
    cleanup = onCleanup(@closeAllFigures);

    checkMultiDTA();
    checkEIS();
    checkCVCSC();
    checkVTResistance();
    checkCIC();
end

function checkMultiDTA()
    fig = launchFigure('gamry_multiDTA_plot_export_gui', 'Gamry Multi-DTA Plot Export GUI');
    assertFigureMinimumSize(fig, 1400, 850);
    assertComponentCounts(fig, struct('Button', 5, 'CheckBox', 2, 'DropDown', 1, ...
        'ListBox', 1, 'TextArea', 2, 'Axes', 2));
    assertButtonContract(fig, {'Open DTA file(s)', 'Open folder recursively', 'Remove selected', ...
        'Clear all', 'Export curves CSV'});
    assertCheckboxContract(fig, {'Show file-name legend', 'Show grid'});
    assertDropdownItems(fig, {'Time (s)', 'Time (ms)', 'Sample #'});
    assertDropdownCallbacksPresent(fig);
    invokeDropdownValue(fig, 'Time (ms)');
    invokeCheckbox(fig, 'Show file-name legend', false);
    invokeButton(fig, 'Clear all');
end

function checkEIS()
    fig = launchFigure('gamry_EIS_multiDTA_plot_gui', 'Gamry EIS Multi-DTA Plot GUI');
    assertFigureMinimumSize(fig, 1400, 850);
    assertComponentCounts(fig, struct('Button', 5, 'CheckBox', 5, 'DropDown', 2, ...
        'ListBox', 1, 'TextArea', 3, 'Axes', 1));
    assertButtonContract(fig, {'Open DTA file(s)', 'Open folder recursively', 'Remove selected', ...
        'Clear all', 'Export current plot CSV'});
    assertCheckboxContract(fig, {'Show markers', 'Log X', 'Log Y', 'Legend', 'Grid'});
    assertDropdownItems(fig, {'Freq (Hz)', 'log10(Freq)', 'Time (s)', 'Point #', ...
        'Zreal (ohm)', 'Zimag (ohm)', '-Zimag (ohm)', 'Zmod (ohm)', 'Zphz (deg)', 'Idc (A)', 'Vdc (V)'});
    assertDropdownCallbacksPresent(fig);
    invokeDropdownValue(fig, 'Freq (Hz)');
    invokeCheckbox(fig, 'Log X', true);
    invokeButton(fig, 'Clear all');
end

function checkCVCSC()
    fig = launchFigure('gamry_CV_CSC_dta_gui', 'Gamry DTA GUI (literature CSC)');
    assertFigureMinimumSize(fig, 1500, 900);
    assertComponentCounts(fig, struct('Button', 7, 'CheckBox', 6, 'DropDown', 6, ...
        'TextArea', 1, 'Axes', 2));
    assertButtonContract(fig, {'Open DTA', 'Reload', 'Auto CV + CT', 'Swap Top/Bottom', ...
        'Compare Q / CSC', 'Refresh Plots', 'Clear Both'});
    assertCheckboxContract(fig, {'Grid', 'Hold', 'Show Trim'});
    assertDropdownItems(fig, {'(none)', 'Full', 'Cathodic', 'Anodic'});
    assertDropdownCallbacksPresent(fig);
    invokeDropdownValue(fig, 'Cathodic');
    invokeButton(fig, 'Refresh Plots');
    invokeButton(fig, 'Clear Both');
end

function checkVTResistance()
    fig = launchFigure('gamry_VT_resistance_gui', 'Gamry VT Steady Resistance GUI');
    assertFigureMinimumSize(fig, 1600, 900);
    assertComponentCounts(fig, struct('Button', 8, 'CheckBox', 4, 'DropDown', 7, ...
        'ListBox', 1, 'Table', 1, 'TextArea', 1, 'Axes', 2));
    assertButtonContract(fig, {'Open DTA file(s)', 'Open folder recursively', 'Clear all', ...
        'Export results CSV', 'Re-analyze file', 'Refresh plots', 'Swap top / bottom', ...
        'Reset axes'});
    assertCheckboxContract(fig, {'Show markers', 'Shade windows', 'Grid'});
    assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    assertDropdownItems(fig, {'Metadata first, then auto', 'Metadata only', 'Auto from Im only', ...
        'Time (s)', 'Sample #', 'VT: Vf vs time', 'IT: Im vs time', ...
        'Full pulse median', 'Center 60% median', 'Baseline-corrected dV/I', 'Raw Vf/I'});
    assertDropdownCallbacksPresent(fig);
    invokeButton(fig, 'Refresh plots');
    invokeButton(fig, 'Reset axes');
    invokeButton(fig, 'Clear all');
end

function checkCIC()
    fig = launchFigure('gamry_CIC_VT_gui_paperlabels', 'Gamry CIC GUI (Voltage Transient)');
    assertFigureMinimumSize(fig, 1600, 900);
    assertComponentCounts(fig, struct('Button', 7, 'CheckBox', 6, 'DropDown', 8, ...
        'ListBox', 1, 'Table', 1, 'TextArea', 1, 'Axes', 2));
    assertButtonContract(fig, {'Open DTA file(s)', 'Open folder recursively', 'Clear all', ...
        'Export results CSV', 'Refresh plots', 'Swap top / bottom', 'Reset axes'});
    assertCheckboxContract(fig, { ...
        'Show debug markers', 'Show window limits', 'Shade pulse windows', ...
        'Use measured Im integration for charge (recommended)'});
    assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    assertDropdownItems(fig, {'Pt (-0.6 to 0.8 V)', 'PEDOT:PSS (-0.9 to 0.6 V)', 'Custom', ...
        'Metadata first, then auto', 'Metadata only', 'Auto from Im only', ...
        'mC/cm^2', 'uC/cm^2', ...
        'Time (s)', 'Sample #', 'VT: Vf vs time', 'IT: Im vs time', ...
        'Cathodic phase', 'Anodic phase', 'Total biphasic'});
    assertDropdownCallbacksPresent(fig);
    invokeButton(fig, 'Refresh plots');
    invokeButton(fig, 'Reset axes');
    invokeButton(fig, 'Clear all');
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

function assertDropdownItems(fig, expectedItems)
    items = string(getAllDropdownItems(fig));
    for k = 1:numel(expectedItems)
        assert(any(items == string(expectedItems{k})), 'Missing dropdown item: %s', expectedItems{k});
    end
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

function assertDropdownCallbacksPresent(fig)
    controls = allGuiObjects(fig);
    for k = 1:numel(controls)
        h = controls{k};
        if contains(class(h), 'DropDown') && isprop(h, 'ValueChangedFcn')
            assertCallbackPresent(h, 'ValueChangedFcn', describeControl(h));
        end
    end
end

function invokeDropdownValue(fig, value)
    controls = allGuiObjects(fig);
    for k = 1:numel(controls)
        h = controls{k};
        if isprop(h, 'Items') && isprop(h, 'Value') && any(strcmp(h.Items, value))
            h.Value = value;
            invokeCallback(h, 'ValueChangedFcn');
            drawnow;
            return;
        end
    end
    error('Dropdown value not found: %s', value);
end

function invokeCheckbox(fig, text, value)
    h = findControlByText(fig, text, 'Value');
    h.Value = value;
    invokeCallback(h, 'ValueChangedFcn');
    drawnow;
end

function invokeButton(fig, text)
    h = findControlByText(fig, text, 'ButtonPushedFcn');
    invokeCallback(h, 'ButtonPushedFcn');
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
        h = controls{k};
        if isprop(h, propertyName)
            v = h.(propertyName);
            if ischar(v) || isstring(v)
                values{end+1} = char(v); %#ok<AGROW>
            end
        end
    end
end

function items = getAllDropdownItems(fig)
    controls = allGuiObjects(fig);
    items = {};
    for k = 1:numel(controls)
        h = controls{k};
        if isprop(h, 'Items')
            current = h.Items;
            if isstring(current)
                current = cellstr(current);
            end
            if iscell(current)
                items = [items, current(:).']; %#ok<AGROW>
            end
        end
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
        f = uifigure('Visible', 'off', 'Name', 'gamrywb_gui_layout_probe');
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
