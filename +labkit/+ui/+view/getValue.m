function value = getValue(ui, id)
%GETVALUE Read a UI 4.0 control value through the semantic registry.
%
% App-facing contract:
%   value = labkit.ui.view.getValue(ui, id)
%
% Inputs:
%   ui - UI registry returned by labkit.ui.app.create.
%   id - globally unique semantic control id.
%
% Output:
%   value - current Value property from the control's primary value handle.

    control = resolveControl(ui, id);
    if isfield(control, 'getValue') && isa(control.getValue, 'function_handle')
        value = control.getValue();
        return;
    end
    handle = controlValueHandle(control);
    if isprop(handle, 'Value')
        value = handle.Value;
    else
        value = [];
    end
end
