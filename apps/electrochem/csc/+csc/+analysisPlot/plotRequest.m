% Expected caller: CSC app runner and unit tests. Inputs are a parsed CV/CT
% curve struct plus selected X/Y header names. Output is the prepared plot
% payload; no file or UI side effects.

function request = plotRequest(curve, xSelection, ySelection)
%PLOTREQUEST Prepare CSC plot data and labels for drawing.

    [x, y, xName, yName] = labkit.dta.getCurveXY(curve, xSelection, ySelection);

    titleText = '';
    if isfield(curve, 'name')
        titleText = curve.name;
    end

    request = struct();
    request.x = x;
    request.y = y;
    request.labels = struct('title', titleText, 'x', xName, 'y', yName);
end
