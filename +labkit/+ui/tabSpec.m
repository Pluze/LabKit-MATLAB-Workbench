function spec = tabSpec(key, titleText, gridSize, rowHeight, opts)
%TABSPEC Build a tab specification for the shared workbench shell.

    if nargin < 4 || isempty(rowHeight)
        rowHeight = repmat({'fit'}, 1, gridSize(1));
    end
    if nargin < 5
        opts = struct();
    end

    spec = struct( ...
        'key', char(key), ...
        'title', char(titleText), ...
        'gridSize', gridSize, ...
        'rowHeight', {asCellRow(rowHeight)}, ...
        'columnWidth', {repmat({'1x'}, 1, gridSize(2))});

    fields = fieldnames(opts);
    for k = 1:numel(fields)
        spec.(fields{k}) = opts.(fields{k});
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
