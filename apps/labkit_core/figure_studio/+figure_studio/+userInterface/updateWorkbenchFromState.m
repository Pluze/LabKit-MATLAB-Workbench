% App-owned renderer for Figure Studio. Expected caller is labkit.ui.app.run.
% Inputs are app state and UI registry. Side effects are limited to visible
% controls, preview axes, status text, and buttons.
function updateWorkbenchFromState(state, ui, ~)
    renderList(state, ui);
    renderControls(state, ui);
    renderPreviewStatus(state, ui);
    clearPreviewFileContextTitle(state, ui);
end

function renderList(state, ui)
    if isempty(state.items)
        labkit.ui.view.setListItems(ui, 'figFiles', {});
        return;
    end
    labkit.ui.view.setValue(ui, 'figFiles', fileEntries(state.items));
    idx = currentIndexOrOne(state);
    files = labkit.ui.view.getFiles(ui, 'figFiles');
    if ~isempty(files)
        labkit.ui.view.setFileSelection(ui, 'figFiles', files(idx));
    end
end

function entries = fileEntries(items)
    entries = repmat(struct('path', '', 'name', '', 'displayName', '', ...
        'status', ''), numel(items), 1);
    for k = 1:numel(items)
        entries(k).path = char(items(k).path);
        entries(k).name = char(items(k).name);
        entries(k).displayName = char(items(k).name);
        entries(k).status = char(items(k).status);
    end
end

function renderControls(state, ui)
    hasFigure = strlength(state.currentSource) > 0;
    enabled = onOff(hasFigure);
    ui.controls.exportCurrent.button.Enable = enabled;
    ui.controls.saveFig.button.Enable = enabled;
    ui.controls.exportPng.button.Enable = enabled;
    ui.controls.exportJpg.button.Enable = enabled;
    ui.controls.exportSvg.button.Enable = enabled;
    ui.controls.outputFolder.valueHandle.Value = char(state.outputFolder);
    ui.controls.currentSource.valueHandle.Value = char(state.currentSource);
    ui.controls.statusSummary.valueHandle.Value = char(join(state.summary, " | "));
    labkit.ui.view.setValue(ui, "stylePreset", char(state.preset));
    labkit.ui.view.setValue(ui, "baseFontSize", state.style.baseFontSize);
    labkit.ui.view.setValue(ui, "titleFontSize", state.style.titleFontSize);
    labkit.ui.view.setValue(ui, "labelFontSize", state.style.labelFontSize);
    labkit.ui.view.setValue(ui, "tickFontSize", state.style.tickFontSize);
    labkit.ui.view.setValue(ui, "dataLineWidth", state.style.dataLineWidth);
    labkit.ui.view.setValue(ui, "axesLineWidth", state.style.axesLineWidth);
    labkit.ui.view.setValue(ui, "gridAlpha", state.style.gridAlpha);
    labkit.ui.view.setValue(ui, "gridVisible", onOffText(state.style.gridVisible));
    labkit.ui.view.setValue(ui, "canvasWidth", state.style.canvasWidth);
    labkit.ui.view.setValue(ui, "canvasHeight", state.style.canvasHeight);
    labkit.ui.view.setValue(ui, "exportScale", state.style.exportScale);
    labkit.ui.view.setValue(ui, "aspectPreset", char(state.aspectPreset));
    labkit.ui.view.setValue(ui, "boundaryLines", onOffText(state.style.boundaryLines));
    renderEmptyPreview(state, ui);
end

function renderPreviewStatus(state, ui)
end

function renderEmptyPreview(state, ui)
    ax = ui.controls.preview.axesById.main;
    if strlength(state.currentSource) > 0 || ~isempty(ax.Children)
        ax.Visible = 'on';
        return;
    end
    cla(ax, 'reset');
    ax.Visible = 'off';
    title(ax, "No figure loaded");
end

function clearPreviewFileContextTitle(state, ui)
    if strlength(state.currentSource) == 0 || ...
            ~isfield(ui.controls, 'preview') || ...
            ~isfield(ui.controls.preview, 'axesById') || ...
            ~isfield(ui.controls.preview.axesById, 'main')
        return;
    end
    ax = ui.controls.preview.axesById.main;
    try
        titleText = join(string(ax.Title.String), " ");
        if contains(titleText, " | file ") || startsWith(titleText, "file ")
            title(ax, "");
        end
    catch
    end
end

function value = onOffText(tf)
    if tf
        value = 'On';
    else
        value = 'Off';
    end
end


function idx = currentIndexOrOne(state)
    idx = state.currentIndex;
    if isempty(idx) || idx < 1 || idx > numel(state.items)
        idx = 1;
    end
end

function value = onOff(tf)
    if tf
        value = 'on';
    else
        value = 'off';
    end
end
