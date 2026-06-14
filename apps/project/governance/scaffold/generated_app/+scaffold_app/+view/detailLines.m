% Expected caller: scaffold_app.run and scaffold_app.ui.buildSpec. Input is
% the app state struct. Output is a cell array of display lines for a status
% panel. No UI handles or app state are mutated.
function lines = detailLines(S)
%DETAILLINES Build scaffold detail lines for display.

    S = normalizeState(S);
    lines = { ...
        'Scaffold app is ready.'; ...
        'Replace placeholder state, callbacks, and summaries with workflow-specific behavior.'; ...
        ['Inputs: ' char(string(numel(S.inputNames)))]; ...
        ['Output folder: ' displayText(S.outputFolder)]; ...
        ['Sample: ' char(S.sampleName)]; ...
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
    if ~isfield(S, 'outputFolder')
        S.outputFolder = "";
    end
    if ~isfield(S, 'sampleName')
        S.sampleName = "Sample";
    end
    if ~isfield(S, 'mode')
        S.mode = "Preview";
    end
    if ~isfield(S, 'lastAction')
        S.lastAction = "Ready";
    end
end

function text = displayText(value)
    value = string(value);
    if strlength(value) == 0
        text = 'none';
    else
        text = char(value);
    end
end
