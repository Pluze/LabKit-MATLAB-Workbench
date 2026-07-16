function layout = panner(id, labelText, varargin)
%PANNER Create a numeric spinner with a linked slider.
%
% Usage:
%   layout = labkit.ui.layout.panner(id, labelText)
%   layout = labkit.ui.layout.panner(id, labelText, Name=Value)
%
% Inputs:
%   id - Text scalar used to identify the panner. It must be a valid MATLAB
%       variable name and unique within the workbench.
%   labelText - Text displayed beside the numeric control.
%
% Name-Value Arguments:
%   limits - Increasing two-element numeric vector. Finite limits create a
%       spinner linked to a slider; an infinite endpoint creates a spinner only.
%       Default: [0 1].
%   value - Initial numeric value. Values outside limits are clamped when the
%       control is built. Default: limits(1).
%   step - Positive absolute spinner step. When omitted, it is inferred from
%       stepFraction for finite limits.
%   stepFraction - Fraction of the finite limit span used for the inferred
%       step. Default: 0.002.
%   minStep - Optional lower bound for the inferred step.
%   maxStep - Optional upper bound for the inferred step.
%   valueDisplayFormat - Numeric display format such as "%.2f".
%   showTicks - Logical value controlling slider ticks. Default: false.
%   enabled - Logical value controlling both spinner and slider. Default: true.
%   onChange - Function handle called as onChange(control,event). event.value
%       is the synchronized value; event.action is "edit" or "slide".
%   debounceMs - Delay before onChange runs, in milliseconds. Default: 500.
%       Use 0 for immediate dispatch.
%   Bind - Runtime V2 path to a scalar project or session value.
%   Event - Action ID dispatched after a bound value is written. Requires Bind.
%
% Outputs:
%   layout - Scalar panner node with kind, id, props, children, and slots fields.
%
% Description:
%   panner gives precise numeric entry and, when both limits are finite, quick
%   slider navigation. Editing either control updates the other before the
%   callback runs. Reassigning the current value does not fire the callback.
%
% Example:
%   frame = labkit.ui.layout.panner("frame", "Frame", ...
%       "limits", [1 100], "value", 1, "step", 1);
%   assert(frame.props.step == 1)
%
% See also labkit.ui.layout.field, labkit.ui.layout.rangeField

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
