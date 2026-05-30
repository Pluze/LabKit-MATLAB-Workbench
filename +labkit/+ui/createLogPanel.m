function ui = createLogPanel(parent, row, initialValue)
%CREATELOGPANEL Create a log panel with a read-only text area.

    if nargin < 2 || isempty(row)
        row = 1;
    end
    if nargin < 3
        initialValue = {'GUI started.'};
    end

    opts = struct('rowHeight', {{'1x'}}, 'columnWidth', {{'1x'}});
    ui = labkit.ui.createPanelGrid(parent, 'Log', row, [1 1], opts);

    ui.textArea = uitextarea(ui.grid, ...
        'Editable', 'off', ...
        'Value', initialValue);
end
