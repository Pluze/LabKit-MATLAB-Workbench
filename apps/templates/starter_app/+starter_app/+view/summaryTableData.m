% Expected caller: starter_app.run and starter_app.ui.buildSpec. Input is
% the app state struct. Output is a 2-column cell table for a resultTable.
% No UI handles or app state are mutated.
function data = summaryTableData(S)
%SUMMARYTABLEDATA Build template summary rows.

    S = normalizeState(S);
    data = { ...
        'Inputs selected', num2str(numel(S.inputNames)); ...
        'Primary value', sprintf('%.2f', double(S.primaryValue)); ...
        'Mode', char(S.mode); ...
        'Run enabled', onOffText(S.enabled); ...
        'Last action', char(S.lastAction)};
end

function S = normalizeState(S)
    if ~isstruct(S)
        S = struct();
    end
    if ~isfield(S, 'inputNames')
        S.inputNames = strings(0, 1);
    end
    if ~isfield(S, 'primaryValue')
        S.primaryValue = 5;
    end
    if ~isfield(S, 'mode')
        S.mode = "Preview";
    end
    if ~isfield(S, 'enabled')
        S.enabled = true;
    end
    if ~isfield(S, 'lastAction')
        S.lastAction = "Ready";
    end
end

function text = onOffText(value)
    if logical(value)
        text = 'on';
    else
        text = 'off';
    end
end
