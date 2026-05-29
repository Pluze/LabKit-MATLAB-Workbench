function ui = createLogPanel(parent, row, initialValue)
%CREATELOGPANEL Create a log panel with a read-only text area.

    if nargin < 2 || isempty(row)
        row = 1;
    end
    if nargin < 3
        initialValue = {'GUI started.'};
    end

    ui = struct();
    ui.panel = uipanel(parent, 'Title', 'Log');
    ui.panel.Layout.Row = row;

    ui.grid = uigridlayout(ui.panel, [1 1]);
    ui.grid.Padding = [8 8 8 8];

    ui.textArea = uitextarea(ui.grid, ...
        'Editable', 'off', ...
        'Value', initialValue);
end
