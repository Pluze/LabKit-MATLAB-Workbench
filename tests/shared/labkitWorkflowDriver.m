function driver = labkitWorkflowDriver(fig)
%LABKITWORKFLOWDRIVER Semantic GUI workflow helper for LabKit app tests.
%
% Expected caller: hidden GUI workflow acceptance tests. Inputs are a LabKit
% app figure with labkitUiRegistry appdata. Output is a small struct of
% app-neutral operations for injecting filePanel choices, invoking controls,
% and reading semantic UI state. The helper mutates only test-injected dialog
% providers and GUI controls through their public callbacks.

    h = guiTestHelpers();
    driver = struct();
    driver.registry = @registry;
    driver.chooseFiles = @chooseFiles;
    driver.click = @(text) h.invokeButton(fig, text);
    driver.dropdown = @(value) h.invokeDropdownValue(fig, value);
    driver.checkbox = @(text, value) h.invokeCheckbox(fig, text, value);
    driver.fileStatus = @fileStatus;
    driver.fileListItems = @fileListItems;
    driver.textAreaValue = @textAreaValue;

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

    function value = textAreaValue(controlId)
        ui = registry();
        id = char(string(controlId));
        assert(isfield(ui.controls, id) && isfield(ui.controls.(id), 'textArea'), ...
            'Workflow text area id not found: %s.', id);
        value = ui.controls.(id).textArea.Value;
    end

    function control = filePanel(panelId)
        ui = registry();
        id = char(string(panelId));
        assert(isfield(ui.controls, id), ...
            'Workflow filePanel id not found: %s.', id);
        control = ui.controls.(id);
        assert(isfield(control, 'status') && isfield(control, 'listbox'), ...
            'Control %s is not a multi-file filePanel.', id);
    end
end
