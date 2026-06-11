function spec = tab(key, titleText, gridSize, rowHeight, opts)
%TABSPEC Build a tab specification for the shared workbench shell.
%
% Usage:
%   spec = labkit.ui.app.tab('filesAnalysis', 'Files + Analysis', ...
%       [4 1], {240, 220, 280, 160});
%
% Inputs:
%   key - valid field-name style identifier used in the returned ui struct.
%   titleText - visible tab title.
%   gridSize - [rows columns] for the tab content grid.
%   rowHeight - optional row-height cell/numeric/string row; default all fit.
%   opts - optional struct copied onto the spec.
%
% Options:
%   columnWidth - cell row of column widths, default all {'1x'}.
%   resize - row-resize behavior: 'betweenRows' default, or 'none'.
%   resizeRows - legacy numeric logical-row boundaries. Prefer resize.
%   resizeOptions - struct passed to row-resize handle creation.
%   padding, rowSpacing, columnSpacing - grid layout properties.
%
% Output:
%   spec - struct consumed by createShell spec options tabs.

    if nargin < 4 || isempty(rowHeight)
        rowHeight = repmat({'fit'}, 1, gridSize(1));
    end
    if nargin < 5
        opts = struct();
    end
    optsHasResize = isfield(opts, 'resize');
    optsHasResizeRows = isfield(opts, 'resizeRows');

    spec = struct( ...
        'key', char(key), ...
        'title', char(titleText), ...
        'gridSize', gridSize, ...
        'rowHeight', {asCellRow(rowHeight)}, ...
        'columnWidth', {repmat({'1x'}, 1, gridSize(2))}, ...
        'resize', 'betweenRows', ...
        'resizeRows', [], ...
        'resizeOptions', struct());

    fields = fieldnames(opts);
    for k = 1:numel(fields)
        spec.(fields{k}) = opts.(fields{k});
    end

    if optsHasResizeRows && isempty(opts.resizeRows) && ~optsHasResize
        spec.resize = 'none';
    end
end

function value = asCellRow(value)
    if iscell(value)
        value = reshape(value, 1, []);
    elseif isstring(value)
        value = cellstr(reshape(value, 1, []));
    elseif isnumeric(value)
        value = num2cell(reshape(value, 1, []));
    else
        value = {value};
    end
end
