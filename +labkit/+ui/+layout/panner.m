function layout = panner(id, labelText, varargin)
%PANNER Create a numeric spinner with a linked slider.
%
% App-facing contract:
%   layout = labkit.ui.layout.panner(id, label, "value", value, ...)
%
% Inputs:
%   id - globally unique panner id.
%   labelText - field label.
%   limits - two-element numeric limits, default [0 1]. Finite limits render
%       a linked slider; infinite limits render the same panner contract as a
%       spinner-only bounded-number control.
%   value - current numeric value, default limits(1).
%   step - absolute spinner step, optional. When omitted, stepFraction is
%       applied to finite limits.
%   stepFraction - fraction of finite limit span for inferred spinner step,
%       default 0.002.
%   minStep, maxStep - optional bounds for inferred spinner step.
%   valueDisplayFormat - optional numeric edit display format, for example
%       "%.2f".
%   showTicks - logical, default false. True shows slider ticks when a slider
%       is rendered.
%   enabled, tooltip, onChange - optional app-neutral props.
%
% Output:
%   layout - scalar data-only UI layout struct.

    props = optionStruct(varargin);
    props.label = char(string(labelText));
    if ~isfield(props, 'limits')
        props.limits = [0 1];
    end
    props.limits = numericLimits(props.limits);
    if ~isfield(props, 'showTicks')
        props.showTicks = false;
    end
    if ~isfield(props, 'value')
        props.value = props.limits(1);
    end
    layout = makeLayoutNode('panner', id, props, {}, struct());
end

function limits = numericLimits(limits)
    limits = double(limits(:)).';
    if numel(limits) ~= 2 || any(isnan(limits)) || limits(1) >= limits(2)
        error('labkit:ui:layout:InvalidPannerLimits', ...
            'panner limits must be an increasing two-element numeric vector.');
    end
end
