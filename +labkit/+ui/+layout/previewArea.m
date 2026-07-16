function layout = previewArea(id, titleText, varargin)
%PREVIEWAREA Create a workspace preview/axes area layout node.
%
% Usage:
%   layout = labkit.ui.layout.previewArea(id, titleText)
%   layout = labkit.ui.layout.previewArea(id, titleText, Name=Value)
%
% Inputs:
%   id - Text scalar used to identify the preview. It must be a valid MATLAB
%       variable name and unique within the workbench.
%   titleText - Text displayed in the preview panel title.
%
% Name-Value Arguments:
%   layout - Axes arrangement: "single", "pair", or "stack". Default:
%       "single".
%   count - Positive integer number of axes. The default is 1 for single and 2
%       for pair or stack. axisIds, when supplied, determines the count.
%   axisIds - Cell array of valid MATLAB field names used to address each axes
%       from presenters and services. Defaults to axis1, axis2, and so on.
%   axisTitles - Cell array of axes titles in axis order. A single axes defaults
%       to titleText; multiple axes default to their axis IDs.
%   xLabels - Cell array of x-axis labels in axis order. Default: blank.
%   yLabels - Cell array of y-axis labels in axis order. Default: blank.
%   columnWidths - uigridlayout ColumnWidth cell array with one entry per axes
%       in pair layout. Default: equal flexible widths.
%   rowHeights - uigridlayout RowHeight cell array with one entry per axes in
%       stack layout. Default: equal flexible heights.
%   scrollZoomAxes - Cell array selecting wheel-zoom dimensions for each axes:
%       "xy", "x", or "y". Invalid or missing entries use "xy".
%   viewModes - Nonempty list of user-facing modes. When supplied, a dropdown
%       is shown above the axes.
%   onModeChange - Function handle called as onModeChange(control,event) when
%       the mode changes. event.mode and event.value contain the selected text.
%
% Outputs:
%   layout - Scalar previewArea node with kind, id, props, children, and slots
%       fields.
%
% Description:
%   previewArea reserves one or more managed uiaxes in the workspace. Runtime
%   renderers address the panel by preview ID and, when needed, an axis ID. Each
%   axes receives the standard LabKit pop-out menu and wheel navigation.
%
% Example:
%   preview = labkit.ui.layout.previewArea("signals", "Signals", ...
%       "layout", "pair", "axisIds", {"input","output"}, ...
%       "xLabels", {"Time (s)","Time (s)"});
%   assert(numel(preview.props.axisIds) == 2)
%
% See also labkit.ui.layout.workspace, labkit.ui.runtime.define

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
