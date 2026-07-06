% Private UI plot helper. Expected caller: named labkit.ui.plot helpers.
% Returns the requested axes from a previewArea or axes-like UI 5 adapter.
function ax = controlAxes(control, axisId)
    if nargin < 2
        axisId = "";
    end

    if strlength(string(axisId)) > 0 && isfield(control, 'axesById')
        name = char(string(axisId));
        if isfield(control.axesById, name)
            ax = control.axesById.(name);
            return;
        end
        error('labkit:ui:plot:UnknownAxes', ...
            'Control "%s" does not have axes "%s".', control.id, name);
    end

    if isfield(control, 'primaryAxes') && isgraphics(control.primaryAxes)
        ax = control.primaryAxes;
        return;
    end
    if isfield(control, 'axes') && isgraphics(control.axes)
        ax = control.axes(1);
        return;
    end
    error('labkit:ui:plot:NoAxes', ...
        'Control "%s" does not expose axes.', control.id);
end
