% Private UI view helper. Expected caller: labkit.ui.view panel, control,
% plot, or text facades. Inputs and outputs are internal UI handles, labels,
% selections, table data, or plot info. Side effects are limited to supplied UI
% parents or axes; assumes the caller owns callbacks and app state.
function ui = logPanel(parent, row, initialValue)
%CREATELOGPANEL Create a log panel with a read-only text area.
%
% Inputs:
%   parent - parent grid.
%   row - optional logical parent row, default 1.
%   initialValue - optional cellstr/string log lines, default {'GUI started.'}.
%
% Output:
%   ui - struct with panel, grid, and textArea fields.

    if nargin < 2 || isempty(row)
        row = 1;
    end
    if nargin < 3
        initialValue = {'GUI started.'};
    end

    opts = struct('rowHeight', {{'1x'}}, 'columnWidth', {{'1x'}});
    ui = labkit.ui.view.section(parent, 'Log', row, [1 1], opts);

    ui.textArea = uitextarea(ui.grid, ...
        'Editable', 'off', ...
        'Value', initialValue);
end
