% Expected caller: CSC UI refresh and tests. Input is the selected comparison
% mode. Output is compact column names for the all-cycle result table.

function names = cycleResultsColumnNames(mode)
%CYCLERESULTSCOLUMNNAMES Return CSC cycle result table columns.

    label = modeLabel(mode);
    names = {'Cycle', 'Rows', ['CV CSC ' label], ['CT CSC ' label], ...
        'Diff (%)', 'Status'};
end

function label = modeLabel(mode)
    choices = csc.userInterface.analysisChoices();
    switch char(string(mode))
        case char(choices.modes(2))
            label = '(cathodic mC/cm^2)';
        case char(choices.modes(3))
            label = '(anodic mC/cm^2)';
        otherwise
            label = '(full mC/cm^2)';
    end
end
