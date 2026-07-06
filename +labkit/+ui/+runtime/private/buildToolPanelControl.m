% Private UI runtime helper. Expected caller: buildControl toolPanel branch.
% Inputs are the UI registry, toolPanel spec, parent grid, and row. Output is
% the updated registry with a semantic host grid for reusable UI tools.
function ui = buildToolPanelControl(ui, toolSpec, parentGrid, row)

    props = toolSpec.props;
    panel = uipanel(parentGrid, ...
        'BorderType', 'none', ...
        'Tag', ['LabKitToolPanel_' toolSpec.id]);
    panel.Layout.Row = row;
    panel.Layout.Column = [1 2];

    grid = uigridlayout(panel, [1 1]);
    grid.RowHeight = {'fit'};
    grid.ColumnWidth = {'1x'};
    grid.RowSpacing = 0;
    grid.ColumnSpacing = 0;
    grid.Padding = [0 0 0 0];

    adapter = struct();
    adapter.id = toolSpec.id;
    adapter.kind = 'toolPanel';
    adapter.layout = toolSpec;
    adapter.props = toolSpec.props;
    adapter.panel = panel;
    adapter.grid = grid;
    adapter.label = optionValue(props, 'label', toolSpec.id);
    ui.controls.(toolSpec.id) = adapter;
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
