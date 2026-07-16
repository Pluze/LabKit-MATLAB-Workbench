% Private UI runtime helper. Expected caller: V2 presentation commit. Updates
% Enable-bearing handles for one semantic control without invoking app code.
function setControlEnabled(ui, id, enabled)
%
% Internal contract:
%   setControlEnabled(ui, id, enabled)
%
% Inputs:
%   ui - UI registry returned by labkit.ui.runtime.create.
%   id - globally unique semantic control id.
%   enabled - logical or MATLAB on/off text.
%
% Output:
%   None. All Enable-bearing handles inside the control adapter are updated.

    control = resolveControl(ui, id);
    handles = controlHandles(control);
    enableText = onOff(enabled);
    for k = 1:numel(handles)
        handle = handles{k};
        if isprop(handle, 'Enable')
            handle.Enable = enableText;
        end
    end
end

function text = onOff(value)
    if islogical(value) && isscalar(value)
        if value
            text = 'on';
        else
            text = 'off';
        end
    else
        text = char(string(value));
    end
end
