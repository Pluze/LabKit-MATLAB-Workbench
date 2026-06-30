% Private UI app layout helper. Expected caller: buildShellFromSpec and
% buildSection. Inputs are one validated UI 3.0 spec and an optional default
% row height. Output is a MATLAB uigridlayout RowHeight value.
function value = specRowHeight(spec, defaultValue)
    if nargin < 2
        defaultValue = 'fit';
    end

    switch spec.kind
        case 'section'
            value = sectionHeight(spec, defaultValue);
        case 'statusPanel'
            value = textPanelHeight(4, 120);
        case 'usagePanel'
            value = textPanelHeight(3, 105);
        case 'logPanel'
            value = textPanelHeight(8, 240);
        case 'filePanel'
            value = filePanelHeight(spec);
        case 'toolPanel'
            value = 356;
        case 'field'
            value = fieldHeight(spec);
        case 'action'
            value = actionHeight(spec);
        case 'resultTable'
            value = tablePanelHeight();
        case 'actionGroup'
            value = actionGroupHeight(spec);
        otherwise
            value = normalizeHeight(defaultValue);
    end
end

function value = sectionHeight(sectionSpec, defaultValue)
    if isempty(sectionSpec.children)
        value = normalizeHeight(defaultValue);
        return;
    end

    rowHeights = zeros(1, numel(sectionSpec.children));
    for k = 1:numel(sectionSpec.children)
        childHeight = specRowHeight(sectionSpec.children{k}, 'fit');
        rowHeights(k) = numericRowHeight(childHeight, defaultControlHeight());
    end

    titleAllowance = sectionTitleAllowance(sectionSpec);
    value = sum(rowHeights) + 8 * max(0, numel(rowHeights) - 1) + ...
        16 + titleAllowance;
end

function value = textPanelHeight(defaultRows, defaultMinHeight)
    value = max(defaultMinHeight, 22 * max(1, double(defaultRows)) + 58);
end

function value = filePanelHeight(spec)
    if strcmp(char(string(optionValue(spec.props, 'mode', 'multi'))), 'single')
        value = 72;
        return;
    end
    rows = 6;
    value = max(185, 22 * max(1, double(rows)) + 104);
end

function value = tablePanelHeight()
    rows = 6;
    value = max(185, 24 * max(1, double(rows)) + 58);
end

function value = actionGroupHeight(groupSpec)
    count = numel(groupSpec.children);
    if count == 0
        value = defaultControlHeight();
        return;
    end
    maxColumns = actionGroupMaxColumns(groupSpec);
    columnCount = min(count, maxColumns);
    rowCount = max(1, ceil(count / columnCount));
    rowHeight = max(defaultControlHeight(), max(actionHeights(groupSpec.children)));
    value = rowCount * rowHeight + ...
        max(0, rowCount - 1) * 6;
end

function value = fieldHeight(fieldSpec)
    props = fieldSpec.props;
    kind = lower(char(string(optionValue(props, 'kind', 'text'))));
    label = string(optionValue(props, 'label', fieldSpec.id));
    if strcmp(kind, 'readonly')
        valueText = string(optionValue(props, 'value', ''));
        value = estimatedTextHeight([label valueText], 34, 3);
    elseif strcmp(kind, 'checkbox')
        value = estimatedTextHeight(label, 42, 2);
    else
        value = estimatedTextHeight(label, 30, 2);
    end
end

function value = actionHeight(actionSpec)
    label = string(optionValue(actionSpec.props, 'label', actionSpec.id));
    value = estimatedTextHeight(label, 22, 2);
end

function values = actionHeights(actions)
    values = zeros(1, max(1, numel(actions)));
    for k = 1:numel(actions)
        values(k) = actionHeight(actions{k});
    end
end

function value = estimatedTextHeight(texts, charsPerLine, maxLines)
    text = join(string(texts(:)), " ");
    lineCount = max(1, ceil(double(max(strlength(splitlines(text)))) ./ charsPerLine));
    lineCount = min(maxLines, lineCount);
    value = max(defaultControlHeight(), 20 * lineCount + 6);
end

function maxColumns = actionGroupMaxColumns(groupSpec)
    maxColumns = 2;
    labels = actionLabels(groupSpec.children);
    if any(strlength(labels) > 28)
        maxColumns = 1;
    end
end

function labels = actionLabels(actions)
    labels = strings(1, numel(actions));
    for k = 1:numel(actions)
        labels(k) = string(optionValue(actions{k}.props, ...
            'label', actions{k}.id));
    end
end

function height = numericRowHeight(value, fallback)
    if isnumeric(value) && isscalar(value) && isfinite(value)
        height = max(1, double(value));
        return;
    end

    text = lower(char(string(value)));
    switch text
        case {'fit'}
            height = fallback;
        otherwise
            height = fallback;
    end
end

function value = normalizeHeight(value)
    if ischar(value) || isstring(value)
        text = char(string(value));
        switch lower(text)
            case {'flex', 'fill', 'grow'}
                value = '1x';
            otherwise
                value = text;
        end
    end
end

function height = defaultControlHeight()
    height = 26;
end

function value = sectionTitleAllowance(sectionSpec)
    value = 0;
    if sectionDrawsOwnTitle(sectionSpec)
        value = 28;
    end
end

function tf = sectionDrawsOwnTitle(sectionSpec)
    tf = true;
    if numel(sectionSpec.children) ~= 1
        return;
    end
    child = sectionSpec.children{1};
    tf = ~ismember(child.kind, ...
        {'previewArea', 'resultTable', 'logPanel', 'statusPanel', ...
        'usagePanel', 'filePanel'});
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
