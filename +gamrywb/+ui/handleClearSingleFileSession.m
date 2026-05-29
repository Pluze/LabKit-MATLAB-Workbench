function state = handleClearSingleFileSession(sessionKind, callbacks)
%HANDLECLEARSINGLEFILESESSION Run the shared clear-all refresh flow.

    state = struct();
    state.session = gamrywb.data.makeSession(sessionKind);
    state.items = state.session.items;
    state.current = [];

    callCallback(callbacks, 'applyState', state.session, state.items, state.current);
    callCallback(callbacks, 'restoreDefaultPlotSelections');
    callCallback(callbacks, 'resetAxesToDefaultState');
    callCallback(callbacks, 'refreshFileList');
    callCallback(callbacks, 'refreshBatchTable');
    callCallback(callbacks, 'refreshResultsSummary');
    callCallback(callbacks, 'refreshPlots');
    callCallback(callbacks, 'addLog', 'Cleared all files.');
end

function callCallback(callbacks, name, varargin)
    if isfield(callbacks, name) && isa(callbacks.(name), 'function_handle')
        callbacks.(name)(varargin{:});
    end
end
