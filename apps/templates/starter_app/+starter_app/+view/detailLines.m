% Expected caller: starter_app.run and starter_app.ui.buildSpec. Input is
% the app state struct. Output is a cell array of display lines for a status
% panel. No UI handles or app state are mutated.
function lines = detailLines(S)
%DETAILLINES Build template detail lines for display.

    S = normalizeState(S);
    lines = { ...
        'This app is a starter canvas for new LabKit apps.'; ...
        'Copy its folder, rename the package and command, then replace the placeholder state with the workflow state.'; ...
        ['Inputs: ' char(string(numel(S.inputNames)))]; ...
        ['Mode: ' char(S.mode)]; ...
        ['Last action: ' char(S.lastAction)]};
end

function S = normalizeState(S)
    if ~isstruct(S)
        S = struct();
    end
    if ~isfield(S, 'inputNames')
        S.inputNames = strings(0, 1);
    end
    if ~isfield(S, 'mode')
        S.mode = "Preview";
    end
    if ~isfield(S, 'lastAction')
        S.lastAction = "Ready";
    end
end
