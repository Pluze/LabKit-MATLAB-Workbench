function spec = panner(id, labelText, varargin)
%PANNER Create a slider with built-in small-step pan buttons.
%
% App-facing contract:
%   spec = labkit.ui.spec.panner(id, label, "value", value, ...)
%
% Inputs:
%   id - globally unique panner id.
%   labelText - field label.
%   limits - two-element numeric slider limits, default [0 1].
%   value - current numeric value, default limits(1).
%   step - absolute button step, optional. When omitted, buttons use
%          stepFraction of the current limit span.
%   stepFraction - fraction of limit span for button step, default 0.002.
%   minStep, maxStep - optional bounds for computed button step.
%   leftLabel, rightLabel - optional button labels, default "<" and ">".
%   enabled, tooltip, onChange - optional app-neutral props.
%
% Output:
%   spec - scalar data-only UI spec struct.

    props = optionStruct(varargin);
    props.label = char(string(labelText));
    if ~isfield(props, 'limits')
        props.limits = [0 1];
    end
    props.limits = numericLimits(props.limits);
    if ~isfield(props, 'value')
        props.value = props.limits(1);
    end
    spec = makeSpec('panner', id, props, {}, struct());
end

function limits = numericLimits(limits)
    limits = double(limits(:)).';
    if numel(limits) ~= 2 || any(~isfinite(limits)) || limits(1) >= limits(2)
        error('labkit:ui:spec:InvalidPannerLimits', ...
            'panner limits must be a finite increasing two-element vector.');
    end
end
