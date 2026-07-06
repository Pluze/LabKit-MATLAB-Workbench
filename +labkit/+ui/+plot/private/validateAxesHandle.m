% Private UI plot axes helper. Expected caller: public axes helper wrappers.
% Inputs are a candidate axes handle and caller name. Output is none; errors
% when the handle is not a valid MATLAB axes or uiaxes.
function validateAxesHandle(ax, callerName)
    if ~(isscalar(ax) && isgraphics(ax) && ...
            (isa(ax, 'matlab.graphics.axis.Axes') || ...
            isa(ax, 'matlab.ui.control.UIAxes')))
        error('labkit:ui:plot:InvalidAxes', ...
            '%s requires a valid scalar axes handle.', char(string(callerName)));
    end
end
