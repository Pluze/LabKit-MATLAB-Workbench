function currentIndex = handleSingleFileSelection(listbox, callbacks)
%HANDLESINGLEFILESELECTION Run the shared single-file selection refresh flow.

    if isempty(listbox.Items)
        currentIndex = [];
        callCallback(callbacks, 'resetAxesToDefaultState');
        callCallback(callbacks, 'refreshResultsSummary');
        callCallback(callbacks, 'refreshPlots');
        return;
    end

    idx = find(strcmp(listbox.Items, listbox.Value), 1);
    if isempty(idx)
        currentIndex = [];
    else
        currentIndex = idx;
    end

    callCallback(callbacks, 'restoreDefaultPlotSelections');
    callCallback(callbacks, 'resetAxesToDefaultState');
    callCallback(callbacks, 'refreshResultsSummary');
    callCallback(callbacks, 'refreshPlots');
end

function callCallback(callbacks, name)
    if isfield(callbacks, name) && isa(callbacks.(name), 'function_handle')
        callbacks.(name)();
    end
end
