% Expected caller: EIS app view code and unit tests. Inputs are the selected
% X/Y axis labels plus optional log-scale flags. Output is the MATLAB axes mode
% needed for that pairing.

function mode = axisModeForSelection(xName, yName, logX, logY)
    if nargin < 3
        logX = false;
    end
    if nargin < 4
        logY = false;
    end
    if strcmp(xName, 'Zreal (ohm)') && ...
            (strcmp(yName, '-Zimag (ohm)') || strcmp(yName, 'Zimag (ohm)')) && ...
            ~logX && ~logY
        mode = "equal";
    else
        mode = "normal";
    end
end
