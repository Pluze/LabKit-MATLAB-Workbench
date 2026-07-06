% Private UI plot helper. Expected caller: named labkit.ui.plot helpers.
% Resolves a semantic preview/control id against a UI 5 registry, or passes
% through an adapter struct already returned by the registry.
function control = resolvePlotControl(uiOrControl, id)
    if nargin < 2
        id = "";
    end

    if isstruct(uiOrControl) && isfield(uiOrControl, 'kind') && ...
            isfield(uiOrControl, 'id')
        control = uiOrControl;
        return;
    end

    if ~(isstruct(uiOrControl) && isfield(uiOrControl, 'controls'))
        error('labkit:ui:plot:InvalidRegistry', ...
            'Expected a UI registry struct returned by labkit.ui.runtime.create.');
    end

    if strlength(string(id)) == 0
        error('labkit:ui:plot:MissingControlId', ...
            'A semantic preview id is required.');
    end

    name = char(string(id));
    if ~isfield(uiOrControl.controls, name)
        error('labkit:ui:plot:UnknownControl', ...
            'Unknown UI preview/control "%s".', name);
    end
    control = uiOrControl.controls.(name);
end
