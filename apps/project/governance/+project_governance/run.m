% Expected caller: labkit_ProjectGovernance_app. Input is a debug context
% prepared by labkit.ui.app.dispatchRequest. Output is the app figure. Side
% effects are optional project metadata creation, code-check report writing,
% and app scaffold generation when users press the matching action.
function fig = run(debugLog)
%RUN Build and run the project governance app.

    S = struct();
    S.root = project_governance.ops.repoRoot();
    S.family = "templates";
    S.slug = "new_app";
    S.entryPoint = "";
    S.label = "New App";
    S.lastAction = "Ready";
    S.lastResult = "Select an action.";

    callbacks = struct( ...
        'settingsChanged', @onSettingsChanged, ...
        'createApp', @onCreateApp, ...
        'createProject', @onCreateProject, ...
        'runCodeCheck', @onRunCodeCheck, ...
        'refreshStatus', @onRefreshStatus);

    spec = project_governance.ui.buildSpec(callbacks);
    ui = labkit.ui.app.create(spec, 'debug', debugLog);
    fig = ui.figure;

    if debugLog.enabled
        debugLog.trace('Project governance debug trace enabled.');
        debugLog.instrumentFigure(fig);
    end

    refreshAll();
    addLog('Project governance ready.');

    function onSettingsChanged(varargin)
        S.family = string(labkit.ui.view.getValue(ui, 'family'));
        S.slug = string(labkit.ui.view.getValue(ui, 'slug'));
        S.entryPoint = string(labkit.ui.view.getValue(ui, 'entryPoint'));
        S.label = string(labkit.ui.view.getValue(ui, 'label'));
        S.lastAction = "Updated scaffold options";
        refreshAll();
    end

    function onCreateApp(~, ~)
        onSettingsChanged();
        try
            created = project_governance.ops.createLabKitApp( ...
                "Family", S.family, ...
                "Slug", S.slug, ...
                "EntryPoint", S.entryPoint, ...
                "Label", S.label);
            S.lastAction = "Created app scaffold";
            S.lastResult = "Created " + created.EntryPoint + " at " + created.AppFolder;
            addLog(S.lastResult);
        catch err
            S.lastAction = "Create app failed";
            S.lastResult = string(err.message);
            addLog("Create app failed: " + S.lastResult);
        end
        refreshAll();
    end

    function onCreateProject(~, ~)
        try
            result = project_governance.ops.createLocalMatlabProject();
            S.lastAction = "Created local MATLAB Project";
            S.lastResult = "Project ready at " + result.ProjectFile;
            addLog(S.lastResult);
        catch err
            S.lastAction = "Create project failed";
            S.lastResult = string(err.message);
            addLog("Create project failed: " + S.lastResult);
        end
        refreshAll();
    end

    function onRunCodeCheck(~, ~)
        try
            report = project_governance.ops.runCodeCheckReport();
            S.lastAction = "Ran Code Analyzer";
            S.lastResult = sprintf('%d messages across %d files. Report: %s', ...
                report.summary.messageCount, ...
                report.summary.filesWithMessages, ...
                report.outputs.json);
            addLog(S.lastResult);
        catch err
            S.lastAction = "Code Analyzer failed";
            S.lastResult = string(err.message);
            addLog("Code Analyzer failed: " + S.lastResult);
        end
        refreshAll();
    end

    function onRefreshStatus(~, ~)
        S.lastAction = "Refreshed status";
        S.lastResult = "Repository root: " + string(S.root);
        addLog(S.lastResult);
        refreshAll();
    end

    function refreshAll()
        labkit.ui.view.setValue(ui, 'family', char(S.family));
        labkit.ui.view.setValue(ui, 'slug', char(S.slug));
        labkit.ui.view.setValue(ui, 'entryPoint', char(S.entryPoint));
        labkit.ui.view.setValue(ui, 'label', char(S.label));
        ui.controls.summaryTable.table.Data = project_governance.view.summaryRows(S);
        ui.controls.details.textArea.Value = project_governance.view.detailLines(S);
    end

    function addLog(message)
        labkit.ui.view.appendLog(ui, 'logPanel', char(message));
        debugLog.append(char(message));
    end
end
