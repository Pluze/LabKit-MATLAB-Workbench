function spec = previewArea(id, titleText, varargin)
%PREVIEWAREA Create a workspace preview/axes area spec.
%
% App-facing contract:
%   spec = labkit.ui.spec.previewArea(id, title, "layout", layout, ...)
%
% Inputs:
%   id - globally unique preview id.
%   titleText - preview area title.
%   layout - single, pair, or stack.
%   viewModes - optional cell array of user-facing view mode labels.
%   onModeChange - optional callback(control, event) for the view-mode
%       selector when viewModes are present.
%   axisIds - optional cell array of valid axis ids.
%   count - optional axes count for stack layouts.
%
% Output:
%   spec - scalar data-only UI spec struct.

    props = optionStruct(varargin);
    props.title = char(string(titleText));
    props.layout = char(string(optionValue(props, 'layout', 'single')));
    validateLayout(props);
    spec = makeSpec('previewArea', id, props, {}, struct());
end

function validateLayout(props)
    allowed = {'single', 'pair', 'stack'};
    if ~any(strcmp(props.layout, allowed))
        error('labkit:ui:spec:InvalidPreviewLayout', ...
            'Unsupported previewArea layout "%s".', props.layout);
    end
    if isfield(props, 'count') && (~isnumeric(props.count) || ...
            ~isscalar(props.count) || props.count < 1 || props.count ~= floor(props.count))
        error('labkit:ui:spec:InvalidPreviewCount', ...
            'previewArea count must be a positive integer scalar.');
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isfield(opts, name)
        value = opts.(name);
    end
end
