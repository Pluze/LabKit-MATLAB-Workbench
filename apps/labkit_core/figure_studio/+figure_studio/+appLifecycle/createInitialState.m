% Expected caller: figure_studio.definition. Inputs are none. Output is the
% deterministic app state for Figure Studio; side effects are none.
function state = createInitialState()
    state = struct();
    state.items = emptyItem();
    state.currentIndex = 0;
    state.outputFolder = string(labkit.ui.app.defaultDialogFolder("output"));
    state.preset = "LabKit figure";
    state.style = figure_studio.styleLibrary.styleForPreset(state.preset);
    state.figDefaultStyle = state.style;
    state.aspectPreset = "4:3";
    state.status = "Load a MATLAB .fig file or send a popout plot to Studio.";
    state.summary = ["No figure loaded."; ...
        "Use the file panel or the popout Send to Studio button."];
    state.currentSource = "";
    state.lastExportFolder = "";
    state.launchAxes = [];
end

function items = emptyItem()
    items = struct( ...
        'path', {}, ...
        'name', {}, ...
        'source', {}, ...
        'status', {});
end
