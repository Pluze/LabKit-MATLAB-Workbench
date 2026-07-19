% Expected caller: CSC app runner and unit tests. Inputs are a parsed CV/CT
% curve struct plus selected X/Y header names and panel name. Output is the
% prepared plot payload and stable log strings; no file or UI side effects.

function request = plotRequest(curve, xSelection, ySelection, panelName)
%PLOTREQUEST Prepare CSC plot data, labels, and log text for runner drawing.

    if nargin < 4
        panelName = 'Plot';
    end

    [x, y, xName, yName] = labkit.dta.getCurveXY(curve, xSelection, ySelection);

    titleText = '';
    if isfield(curve, 'name')
        titleText = curve.name;
    end

    request = struct();
    request.x = x;
    request.y = y;
    request.labels = struct('title', titleText, 'x', xName, 'y', yName);
    request.skipLog = sprintf('%s plot skipped: invalid X/Y.', panelName);
    request.successLog = sprintf('%s plot: %s vs %s, n=%d', ...
        panelName, yName, xName, numel(x));
end
