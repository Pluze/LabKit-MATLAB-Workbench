% Expected caller: EIS app view code and unit tests. Inputs are the selected
% X/Y axis labels. Output is the MATLAB axes mode needed for that pairing.

function mode = axisModeForSelection(xName, yName)
    if strcmp(xName, 'Zreal (ohm)') && ...
            (strcmp(yName, '-Zimag (ohm)') || strcmp(yName, 'Zimag (ohm)'))
        mode = "equal";
    else
        mode = "normal";
    end
end
