% Expected caller: scaffold_App_app. Input is a debug context prepared by
% labkit.ui.app.dispatchRequest. Output is the app figure. Side effects are
% GUI creation, scaffold-state updates, and debug trace attachment.
function fig = run(debugLog)
%RUN Build and run the LabKit Scaffold App.

    S = struct();
    S.inputNames = strings(0, 1);
    S.outputFolder = "";
    S.sampleName = "Sample";
    S.repeatCount = 1;
    S.threshold = 0.50;
    S.primaryValue = 5;
    S.mode = "Preview";
    S.enabled = true;
    S.lastAction = "Ready";

    callbacks = struct( ...
        'inputsChosen', @onInputsChosen, ...
        'inputsCleared', @onInputsCleared, ...
        'outputFolderChosen', @onOutputFolderChosen, ...
        'outputFolderCleared', @onOutputFolderCleared, ...
        'inputSelectionChanged', @onInputSelectionChanged, ...
        'settingChanged', @onSettingChanged, ...
        'previewModeChanged', @onPreviewModeChanged, ...
        'runWorkflow', @onRunWorkflow, ...
        'resetWorkflow', @onResetWorkflow);

    spec = scaffold_app.ui.buildSpec(callbacks);
    ui = labkit.ui.app.create(spec, 'debug', debugLog);
    fig = ui.figure;

    if debugLog.enabled
        debugLog.trace('Scaffold app debug trace enabled.');
        debugLog.instrumentFigure(fig);
    end

    refreshAll();
    addLog('Scaffold app ready.');

    function onInputsChosen(~, event)
        names = eventPaths(event);
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
        addLog('Cleared scaffold inputs.');
        refreshAll();
    end

    function onOutputFolderChosen(~, event)
        paths = eventPaths(event);
        if ~isempty(paths)
            S.outputFolder = paths(1);
            S.lastAction = "Selected output folder";
            refreshAll();
        end
    end

    function onOutputFolderCleared(~, ~)
        S.outputFolder = "";
        S.lastAction = "Cleared output folder";
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
        S.sampleName = string(labkit.ui.view.getValue(ui, 'sampleName'));
        S.repeatCount = labkit.ui.view.getValue(ui, 'repeatCount');
        S.threshold = labkit.ui.view.getValue(ui, 'threshold');
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

    function onRunWorkflow(~, ~)
        S.lastAction = "Ran scaffold workflow";
        addLog('Ran the scaffold placeholder workflow.');
        refreshAll();
    end

    function onResetWorkflow(~, ~)
        S.inputNames = strings(0, 1);
        S.outputFolder = "";
        S.sampleName = "Sample";
        S.repeatCount = 1;
        S.threshold = 0.50;
        S.primaryValue = 5;
        S.mode = "Preview";
        S.enabled = true;
        S.lastAction = "Reset scaffold";
        labkit.ui.view.setValue(ui, 'sampleName', char(S.sampleName));
        labkit.ui.view.setValue(ui, 'repeatCount', S.repeatCount);
        labkit.ui.view.setValue(ui, 'threshold', S.threshold);
        labkit.ui.view.setValue(ui, 'primaryValue', S.primaryValue);
        labkit.ui.view.setValue(ui, 'mode', char(S.mode));
        labkit.ui.view.setValue(ui, 'enableOption', S.enabled);
        addLog('Reset scaffold state.');
        refreshAll();
    end

    function refreshAll()
        labkit.ui.view.setListItems(ui, 'inputs', cellstr(S.inputNames));
        labkit.ui.view.setListSelection(ui, 'inputs', cellstr(S.inputNames), {});
        labkit.ui.view.setEnabled(ui, 'runWorkflow', S.enabled);
        ui.controls.summaryTable.table.Data = scaffold_app.view.summaryTableData(S);
        ui.controls.details.textArea.Value = scaffold_app.view.detailLines(S);
        refreshPreview();
    end

    function refreshPreview()
        canvas = scaffoldCanvas(S);
        labkit.ui.view.drawImage(ui, 'preview', canvas, ...
            'axis', 'main', 'title', char("Scaffold " + S.mode));
    end

    function addLog(message)
        labkit.ui.view.appendLog(ui, 'logPanel', message);
        debugLog.append(message);
    end
end

function paths = eventPaths(event)
    paths = strings(0, 1);
    if isstruct(event) && isfield(event, 'paths')
        paths = event.paths;
    elseif isobject(event) && isprop(event, 'paths')
        paths = event.paths;
    end
    if ~(isstring(paths) && iscolumn(paths))
        error('scaffold_app:InvalidPathEvent', ...
            'pathPanel event paths must be a string column.');
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

function canvas = scaffoldCanvas(S)
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
