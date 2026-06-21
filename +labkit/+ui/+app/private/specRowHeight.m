% Private UI app layout helper. Expected caller: buildShellFromSpec and
% buildSection. Inputs are one validated UI 2.0 spec and an optional default
% row height. Output is a MATLAB uigridlayout RowHeight value.
function value = specRowHeight(spec, defaultValue)
    if nargin < 2
        defaultValue = 'fit';
    end

    props = spec.props;
    switch spec.kind
        case 'section'
            value = sectionHeight(spec, defaultValue);
        case 'statusPanel'
            value = textPanelHeight(props, 4, 120);
        case 'logPanel'
            value = textPanelHeight(props, 8, 240);
        case 'pathPanel'
            value = pathPanelHeight(props);
        case 'resultTable'
            value = tablePanelHeight(props);
        case 'actionGroup'
            value = actionGroupHeight(spec);
        otherwise
            value = normalizeHeight(defaultValue);
    end

    if isfield(props, 'height')
        explicitHeight = normalizeHeight(props.height);
        if strcmp(spec.kind, 'section') && isNumericHeight(explicitHeight) && ...
                isNumericHeight(value)
            value = max(double(explicitHeight), double(value));
        else
            value = explicitHeight;
        end
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

    spacing = optionValue(sectionSpec.props, 'rowSpacing', 8);
    padding = optionValue(sectionSpec.props, 'padding', [8 8 8 8]);
    titleAllowance = sectionTitleAllowance(sectionSpec);
    value = sum(rowHeights) + spacing * max(0, numel(rowHeights) - 1) + ...
        padding(2) + padding(4) + titleAllowance;
end

function value = textPanelHeight(props, defaultRows, defaultMinHeight)
    rows = optionValue(props, 'minRows', defaultRows);
    value = max(optionValue(props, 'minHeight', defaultMinHeight), ...
        22 * max(1, double(rows)) + 58);
end

function value = pathPanelHeight(props)
    rows = optionValue(props, 'minRows', defaultPathRows(props));
    value = max(optionValue(props, 'minHeight', defaultPathMinHeight(props)), ...
        22 * max(1, double(rows)) + 96);
end

function value = tablePanelHeight(props)
    rows = optionValue(props, 'minRows', 6);
    value = max(optionValue(props, 'minHeight', 185), ...
        24 * max(1, double(rows)) + 58);
end

function value = actionGroupHeight(groupSpec)
    count = numel(groupSpec.children);
    if count == 0
        value = defaultControlHeight();
        return;
    end
    maxColumns = max(1, round(double(optionValue(groupSpec.props, ...
        'maxColumns', 2))));
    columnCount = min(count, maxColumns);
    rowCount = max(1, ceil(count / columnCount));
    rowSpacing = optionValue(groupSpec.props, 'rowSpacing', 6);
    value = rowCount * defaultControlHeight() + ...
        max(0, rowCount - 1) * double(rowSpacing);
end

function rows = defaultPathRows(~)
    rows = 5;
end

function value = defaultPathMinHeight(~)
    value = 165;
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
            case {'fit', 'fixed'}
                value = 'fit';
            case {'flex', 'fill', 'grow'}
                value = '1x';
            otherwise
                value = text;
        end
    end
end

function tf = isNumericHeight(value)
    tf = isnumeric(value) && isscalar(value) && isfinite(value);
end

function height = defaultControlHeight()
    height = 26;
end

function value = sectionTitleAllowance(sectionSpec)
    value = 0;
    if sectionDrawsOwnTitle(sectionSpec) && hasPanelChrome(sectionSpec)
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
        {'previewArea', 'resultTable', 'logPanel', 'statusPanel', 'pathPanel'});
end

function tf = hasPanelChrome(sectionSpec)
    chrome = optionValue(sectionSpec.props, 'chrome', 'panel');
    tf = ~strcmpi(char(string(chrome)), 'none');
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
