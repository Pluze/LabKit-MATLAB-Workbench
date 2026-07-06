% Expected caller: labkit_FigureStudio_app. Inputs are public entrypoint
% varargin values. Output separates Studio-specific launch requests from
% ordinary LabKit dispatchRequest arguments. Side effects are none.
function [request, dispatchArgs] = launchRequest(args)
    request = struct("hasAxes", false, "axes", []);
    dispatchArgs = args;
    if numel(args) >= 2 && isScalarText(args{1}) && string(args{1}) == "axes"
        ax = args{2};
        if isempty(ax) || ~isvalid(ax)
            error('labkit_FigureStudio_app:InvalidAxes', ...
                'Figure Studio axes launch requires a valid axes handle.');
        end
        request.hasAxes = true;
        request.axes = ax;
        dispatchArgs = {};
    end
end

function tf = isScalarText(value)
    tf = ischar(value) || (isstring(value) && isscalar(value));
end
