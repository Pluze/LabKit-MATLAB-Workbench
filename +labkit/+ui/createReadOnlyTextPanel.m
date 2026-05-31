function ui = createReadOnlyTextPanel(parent, titleText, row, lines, opts)
%CREATEREADONLYTEXTPANEL Create a titled read-only multi-line text panel.

    if nargin < 4 || isempty(lines)
        lines = {};
    end
    if nargin < 5
        opts = struct();
    end

    panelOpts = struct( ...
        'rowHeight', {{'1x'}}, ...
        'columnWidth', {{'1x'}});
    if isfield(opts, 'panelOptions')
        panelOpts = mergeStruct(panelOpts, opts.panelOptions);
    end

    ui = labkit.ui.createPanelGrid(parent, titleText, row, [1 1], panelOpts);
    ui.textArea = uitextarea(ui.grid, 'Editable', 'off');
    ui.textArea.Value = lines;
end

function out = mergeStruct(out, in)
    fields = fieldnames(in);
    for k = 1:numel(fields)
        out.(fields{k}) = in.(fields{k});
    end
end
