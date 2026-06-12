% Private UI view helper. Expected caller: named labkit.ui.view helpers.
% Resolves a semantic control id against a UI 2.0 registry, or passes through
% an adapter struct already returned by the registry.
function control = resolveControl(uiOrControl, id)
    if nargin < 2
        id = "";
    end

    if isstruct(uiOrControl) && isfield(uiOrControl, 'kind') && ...
            isfield(uiOrControl, 'id')
        control = uiOrControl;
        return;
    end

    if ~(isstruct(uiOrControl) && isfield(uiOrControl, 'controls'))
        error('labkit:ui:view:InvalidRegistry', ...
            'Expected a UI registry struct returned by labkit.ui.app.create.');
    end

    if strlength(string(id)) == 0
        error('labkit:ui:view:MissingControlId', ...
            'A semantic control id is required.');
    end

    name = char(string(id));
    if ~isfield(uiOrControl.controls, name)
        error('labkit:ui:view:UnknownControl', ...
            'Unknown UI control "%s".', name);
    end
    control = uiOrControl.controls.(name);
end
