function driver = labkitWorkflowDriver(fig)
%LABKITWORKFLOWDRIVER Semantic GUI workflow helper for LabKit app tests.
%
% Expected caller: hidden GUI workflow acceptance tests. Inputs are a LabKit
% app figure with labkitUiRegistry appdata. Output is a small struct of
% app-neutral operations for injecting filePanel choices, invoking controls,
% setting active tool anchors, and reading semantic UI state. The helper
% mutates only test-injected dialog providers, active LabKit UI tools, and GUI
% controls through their public callbacks.

    h = guiTestHelpers();
    driver = struct();
    driver.registry = @registry;
    driver.chooseFiles = @chooseFiles;
    driver.click = @(text) h.invokeButton(fig, text);
    driver.dropdown = @(value) h.invokeDropdownValue(fig, value);
    driver.checkbox = @(text, value) h.invokeCheckbox(fig, text, value);
    driver.fileStatus = @fileStatus;
    driver.fileListItems = @fileListItems;
    driver.fileSelection = @fileSelection;
    driver.selectFile = @selectFile;
    driver.tableData = @tableData;
    driver.textAreaValue = @textAreaValue;
    driver.logValue = @logValue;
    driver.enabled = @enabled;
    driver.previewChildCount = @previewChildCount;
    driver.setAnchorPoints = @setAnchorPoints;

    function ui = registry()
        assert(isappdata(fig, 'labkitUiRegistry'), ...
            'Workflow driver requires a LabKit UI registry on the app figure.');
        ui = getappdata(fig, 'labkitUiRegistry');
    end

    function chooseFiles(panelId, paths)
        ui = registry();
        id = char(string(panelId));
        assert(isfield(ui.controls, id), ...
            'Workflow filePanel id not found: %s.', id);
        ui.controls.(id).props.dialogProvider = @(~) string(paths);
        setappdata(fig, 'labkitUiRegistry', ui);
    end

    function text = fileStatus(panelId)
        control = filePanel(panelId);
        text = string(control.status.Value);
    end

    function items = fileListItems(panelId)
        control = filePanel(panelId);
        items = string(control.listbox.Items);
    end

    function value = fileSelection(panelId)
        control = filePanel(panelId);
        value = string(control.listbox.Value);
    end

    function selectFile(panelId, pathOrLabel)
        control = filePanel(panelId);
        labels = string(control.listbox.Items);
        match = find(contains(labels, string(pathOrLabel)), 1, 'first');
        assert(~isempty(match), ...
            'Workflow filePanel %s has no item matching %s.', ...
            char(string(panelId)), char(string(pathOrLabel)));
        control.listbox.Value = control.listbox.Items{match};
        callback = control.listbox.ValueChangedFcn;
        assert(isa(callback, 'function_handle'), ...
            'Workflow filePanel %s has no selection callback.', ...
            char(string(panelId)));
        callback(control.listbox, struct());
        drawnow;
    end

    function value = textAreaValue(controlId)
        ui = registry();
        id = char(string(controlId));
        assert(isfield(ui.controls, id) && isfield(ui.controls.(id), 'textArea'), ...
            'Workflow text area id not found: %s.', id);
        value = ui.controls.(id).textArea.Value;
    end

    function value = logValue(controlId)
        value = textAreaValue(controlId);
    end

    function data = tableData(controlId)
        ui = registry();
        id = char(string(controlId));
        assert(isfield(ui.controls, id) && isfield(ui.controls.(id), 'table'), ...
            'Workflow table id not found: %s.', id);
        data = ui.controls.(id).table.Data;
    end

    function tf = enabled(controlId)
        control = semanticControl(controlId);
        handles = controlHandles(control);
        enabledValues = false(size(handles));
        for k = 1:numel(handles)
            enabledValues(k) = isprop(handles{k}, 'Enable') && ...
                strcmp(char(handles{k}.Enable), 'on');
        end
        tf = any(enabledValues);
    end

    function n = previewChildCount(controlId)
        control = semanticControl(controlId);
        assert(isfield(control, 'primaryAxes'), ...
            'Workflow preview id not found: %s.', char(string(controlId)));
        n = numel(control.primaryAxes.Children);
    end

    function setAnchorPoints(controlId, points)
        control = semanticControl(controlId);
        assert(isfield(control, 'primaryAxes'), ...
            'Workflow preview id not found: %s.', char(string(controlId)));
        ax = control.primaryAxes;
        key = 'labkit_ui_activeAnchorEditor';
        assert(isappdata(ax, key), ...
            'No active LabKit anchor editor is registered for preview %s.', ...
            char(string(controlId)));
        registered = getappdata(ax, key);
        assert(isstruct(registered) && isfield(registered, 'editor'), ...
            'Registered anchor editor for preview %s is malformed.', ...
            char(string(controlId)));
        editor = registered.editor;
        assert(isstruct(editor) && isfield(editor, 'setPoints') && ...
            isa(editor.setPoints, 'function_handle'), ...
            'Registered anchor editor for preview %s does not support setPoints.', ...
            char(string(controlId)));
        editor.setPoints(points);
    end

    function control = filePanel(panelId)
        control = semanticControl(panelId);
        assert(isfield(control, 'status') && isfield(control, 'listbox'), ...
            'Control %s is not a multi-file filePanel.', char(string(panelId)));
    end

    function control = semanticControl(controlId)
        ui = registry();
        id = char(string(controlId));
        assert(isfield(ui.controls, id), ...
            'Workflow control id not found: %s.', id);
        control = ui.controls.(id);
    end

    function handles = controlHandles(control)
        names = fieldnames(control);
        handles = cell(1, numel(names));
        count = 0;
        for k = 1:numel(names)
            value = control.(names{k});
            if isscalar(value) && isobject(value) && isvalid(value) && ...
                    isprop(value, 'Enable')
                count = count + 1;
                handles{count} = value;
            end
        end
        handles = handles(1:count);
    end
end
