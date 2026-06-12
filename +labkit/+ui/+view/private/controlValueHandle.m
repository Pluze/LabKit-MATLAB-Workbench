% Private UI view helper. Expected caller: named labkit.ui.view helpers.
% Returns the primary value-bearing MATLAB handle from a UI 2.0 control
% adapter. The adapter shape is internal and may vary by spec family.
function handle = controlValueHandle(control)
    if isfield(control, 'valueHandle') && isvalidHandle(control.valueHandle)
        handle = control.valueHandle;
        return;
    end
    for name = {'handle', 'listbox', 'textArea', 'table', 'button'}
        field = name{1};
        if isfield(control, field) && isvalidHandle(control.(field))
            handle = control.(field);
            return;
        end
    end
    error('labkit:ui:view:NoValueHandle', ...
        'Control "%s" does not expose a value handle.', control.id);
end

function tf = isvalidHandle(value)
    tf = ~isempty(value) && isgraphics(value) && isvalid(value);
end
