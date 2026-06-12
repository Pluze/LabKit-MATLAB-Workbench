% Expected caller: labkit_TemplateApp_app. Input is a debug context prepared
% by labkit.ui.app.dispatchRequest. Output is the app figure. Side effects are
% GUI creation, synthetic template-state updates, and debug trace attachment.
function fig = run(debugLog)
%RUN Build and run the LabKit Template App.

    S = struct();
    S.inputNames = strings(0, 1);
    S.primaryValue = 5;
    S.mode = "Preview";
    S.enabled = true;
    S.lastAction = "Ready";

    callbacks = struct( ...
        'inputsChosen', @onInputsChosen, ...
        'inputsCleared', @onInputsCleared, ...
        'inputSelectionChanged', @onInputSelectionChanged, ...
        'settingChanged', @onSettingChanged, ...
        'previewModeChanged', @onPreviewModeChanged, ...
        'runTemplate', @onRunTemplate, ...
        'resetTemplate', @onResetTemplate);

    spec = starter_app.ui.buildSpec(callbacks);
    ui = labkit.ui.app.create(spec, 'debug', debugLog);
    fig = ui.figure;

    if debugLog.enabled
        debugLog.trace('Template app debug trace enabled.');
        debugLog.instrumentFigure(fig);
    end

    refreshAll();
    addLog('Template app ready.');

    function onInputsChosen(~, event)
        names = strings(0, 1);
        if isstruct(event) && isfield(event, 'paths')
            names = string(event.paths(:));
        elseif isobject(event) && isprop(event, 'paths')
            names = string(event.paths(:));
        end
        if isempty(names)
            names = "Selected item";
        else
            [~, base, ext] = cellfun(@fileparts, cellstr(names), ...
                'UniformOutput', false);
            names = string(strcat(base, ext));
        end
        S.inputNames = names(:);
        S.lastAction = "Selected input placeholder";
        addLog(sprintf('Recorded %d selected input name(s).', numel(S.inputNames)));
        refreshAll();
    end

    function onInputsCleared(~, ~)
        S.inputNames = strings(0, 1);
        S.lastAction = "Cleared inputs";
        addLog('Cleared template inputs.');
        refreshAll();
    end

    function onInputSelectionChanged(~, event)
        value = eventValue(event);
        if strlength(value) > 0
            S.lastAction = "Selected " + value;
            refreshAll();
        end
    end

    function onSettingChanged(~, ~)
        S.primaryValue = labkit.ui.view.getValue(ui, 'primaryValue');
        S.mode = string(labkit.ui.view.getValue(ui, 'mode'));
        S.enabled = logical(labkit.ui.view.getValue(ui, 'enableOption'));
        S.lastAction = "Updated settings";
        refreshAll();
    end

    function onPreviewModeChanged(~, event)
        value = eventValue(event);
        if strlength(value) > 0
            S.mode = value;
        end
        S.lastAction = "Changed preview mode";
        refreshAll();
    end

    function onRunTemplate(~, ~)
        S.lastAction = "Ran template workflow";
        addLog('Ran the template placeholder workflow.');
        refreshAll();
    end

    function onResetTemplate(~, ~)
        S.inputNames = strings(0, 1);
        S.primaryValue = 5;
        S.mode = "Preview";
        S.enabled = true;
        S.lastAction = "Reset template";
        labkit.ui.view.setValue(ui, 'primaryValue', S.primaryValue);
        labkit.ui.view.setValue(ui, 'mode', char(S.mode));
        labkit.ui.view.setValue(ui, 'enableOption', S.enabled);
        addLog('Reset template state.');
        refreshAll();
    end

    function refreshAll()
        labkit.ui.view.setListItems(ui, 'inputs', cellstr(S.inputNames));
        labkit.ui.view.setListSelection(ui, 'inputs', cellstr(S.inputNames), {});
        labkit.ui.view.setEnabled(ui, 'runTemplate', S.enabled);
        ui.controls.summaryTable.table.Data = starter_app.view.summaryTableData(S);
        ui.controls.details.textArea.Value = starter_app.view.detailLines(S);
        refreshPreview();
    end

    function refreshPreview()
        canvas = templateCanvas(S);
        labkit.ui.view.drawImage(ui, 'preview', canvas, ...
            'axis', 'main', 'title', char("Template " + S.mode));
    end

    function addLog(message)
        labkit.ui.view.appendLog(ui, 'logPanel', message);
        debugLog.append(message);
    end
end

function value = eventValue(event)
    value = "";
    if isstruct(event) && isfield(event, 'value')
        value = string(event.value);
    elseif isobject(event) && isprop(event, 'value')
        value = string(event.value);
    end
    if numel(value) > 1
        value = value(1);
    end
end

function canvas = templateCanvas(S)
    width = 240;
    height = 160;
    [x, y] = meshgrid(linspace(0, 1, width), linspace(0, 1, height));
    scale = max(0, min(1, double(S.primaryValue) / 10));
    canvas = zeros(height, width, 3);
    canvas(:, :, 1) = x .* scale + 0.10;
    canvas(:, :, 2) = y .* 0.70 + 0.15;
    canvas(:, :, 3) = (1 - x) .* (1 - 0.5 * scale) + 0.10;
    if ~S.enabled
        gray = mean(canvas, 3);
        canvas = repmat(gray, 1, 1, 3);
    end
end
