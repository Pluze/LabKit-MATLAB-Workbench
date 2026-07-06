function layout = previewArea(id, titleText, varargin)
%PREVIEWAREA Create a workspace preview/axes area layout node.
%
% App-facing contract:
%   layout = labkit.ui.layout.previewArea(id, title, "layout", layout, ...)
%
% Inputs:
%   id - globally unique preview id.
%   titleText - preview area title.
%   layout - single, pair, or stack.
%   viewModes - optional cell array of user-facing view mode labels.
%   onModeChange - optional callback(control, event) for the view-mode
%       selector when viewModes are present.
%   axisIds - optional cell array of valid axis ids.
%   axisTitles, xLabels, yLabels - optional axis label cell arrays.
%   columnWidths - optional uigridlayout ColumnWidth cell for pair layouts.
%   rowHeights - optional uigridlayout RowHeight cell for stack layouts.
%   count - optional axes count for stack layouts.
%
% Output:
%   layout - scalar data-only UI layout struct.

    props = optionStruct(varargin);
    props.title = char(string(titleText));
    props.layout = char(string(optionValue(props, 'layout', 'single')));
    validateLayout(props);
    layout = makeLayoutNode('previewArea', id, props, {}, struct());
end

function validateLayout(props)
    allowed = {'single', 'pair', 'stack'};
    if ~any(strcmp(props.layout, allowed))
        error('labkit:ui:layout:InvalidPreviewLayout', ...
            'Unsupported previewArea layout "%s".', props.layout);
    end
    if isfield(props, 'count') && (~isnumeric(props.count) || ...
            ~isscalar(props.count) || props.count < 1 || props.count ~= floor(props.count))
        error('labkit:ui:layout:InvalidPreviewCount', ...
            'previewArea count must be a positive integer scalar.');
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isfield(opts, name)
        value = opts.(name);
    end
end
