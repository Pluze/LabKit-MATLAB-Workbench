function layout = field(id, labelText, varargin)
%FIELD Create a labeled scalar field layout node.
%
% Usage:
%   layout = labkit.ui.layout.field(id, labelText)
%   layout = labkit.ui.layout.field(id, labelText, Name=Value)
%
% Inputs:
%   id - Text scalar used to identify the field. It must be a valid MATLAB
%       variable name and unique within the workbench.
%   labelText - Text displayed beside the field. A checkbox displays it as the
%       checkbox label.
%
% Name-Value Arguments:
%   kind - Control type: "text", "number", "spinner", "dropdown", "slider",
%       "checkbox", or "readonly". Default: "text".
%   value - Initial control value. When omitted, the selected MATLAB control's
%       default value is used.
%   items - Dropdown choices as text, a string array, or cellstr. Used only by
%       kind="dropdown".
%   limits - Two-element numeric limits for number, spinner, or slider fields.
%   step - Spinner step size.
%   valueDisplayFormat - MATLAB numeric display format such as "%.3f".
%   showTicks - Logical value controlling slider tick marks. MATLAB's slider
%       ticks are used when omitted; false hides both major and minor ticks.
%   enabled - Logical value controlling whether the field accepts input.
%       Default: true.
%   onChange - Function handle called as onChange(control,event). event.value
%       contains the current field value.
%   debounceMs - Delay before onChange runs, in milliseconds. A later change
%       restarts the delay. Default: 500. Use 0 for immediate dispatch.
%   Bind - Runtime V2 state path such as "project.parameters.gain" or
%       "session.selection.channel". The path must exist in initial state.
%   Event - Action ID dispatched after a bound value is written. Event requires
%       Bind; omit Event when the binding alone is sufficient.
%
% Outputs:
%   layout - Scalar field node with kind, id, props, children, and slots fields.
%
% Description:
%   field covers common single-value controls. In a Runtime V2 app, Bind makes
%   state the source of truth: the runtime initializes the control from that
%   path, writes user changes back, and then dispatches Event when supplied.
%   Without Bind, onChange is the low-level callback used by runtime.create.
%
% Errors:
%   labkit:ui:layout:InvalidFieldKind - kind is not one of the documented
%   control types.
%   labkit:ui:layout:InvalidId, InvalidOptions, or InvalidOptionName - id or
%   Name-value syntax is malformed. Control-specific values are validated
%   when the runtime builds the node.
%
% Example:
%   gain = labkit.ui.layout.field("gain", "Gain", ...
%       "kind", "spinner", "value", 2, "limits", [0 10], "step", 0.5);
%   assert(gain.props.value == 2)
%
% See also labkit.ui.layout.panner, labkit.ui.layout.rangeField

    props = optionStruct(varargin);
    props.label = char(string(labelText));
    props.kind = char(string(optionValue(props, 'kind', 'text')));
    validateFieldKind(props.kind);
    layout = makeLayoutNode('field', id, props, {}, struct());
end

function validateFieldKind(kind)
    allowed = {'text', 'number', 'spinner', 'dropdown', 'slider', ...
        'checkbox', 'readonly'};
    if ~any(strcmpi(kind, allowed))
        error('labkit:ui:layout:InvalidFieldKind', ...
            'Unsupported declarative field kind "%s".', kind);
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isfield(opts, name)
        value = opts.(name);
    end
end
