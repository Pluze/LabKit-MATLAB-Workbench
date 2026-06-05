function ui = textPanel(parent, titleText, row, lines, opts)
%CREATEREADONLYTEXTPANEL Create a titled read-only multi-line text panel.
%
% Inputs:
%   parent - parent grid.
%   titleText - panel title.
%   row - logical parent row.
%   lines - cellstr/string lines, default empty.
%   opts - optional struct.
%
% Options:
%   panelOptions - struct forwarded to labkit.ui.view.section.
%
% Output:
%   ui - struct with panel, grid, and textArea fields.

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

    ui = labkit.ui.view.section(parent, titleText, row, [1 1], panelOpts);
    ui.textArea = uitextarea(ui.grid, 'Editable', 'off');
    ui.textArea.Value = lines;
end

function out = mergeStruct(out, in)
    fields = fieldnames(in);
    for k = 1:numel(fields)
        out.(fields{k}) = in.(fields{k});
    end
end
