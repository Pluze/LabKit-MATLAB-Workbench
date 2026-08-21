% Expected caller: CSC app runner and unit tests. Input is the current numeric
% curve column list. Output is the stable top/bottom plot default selection
% struct. No file or UI side effects.

function selections = defaultPlotSelections(columns)
%DEFAULTPLOTSELECTIONS Choose CSC top/bottom axis defaults.

    columns = cellstr(columns);
    selections = struct();
    selections.topX = chooseColumn(columns, 'Vf');
    selections.topY = chooseColumn(columns, 'Im');
    selections.bottomX = chooseColumn(columns, 'T');
    selections.bottomY = chooseColumn(columns, 'Im');
end

function value = chooseColumn(columns, preferred)
    if any(strcmp(columns, preferred))
        value = preferred;
    elseif ~isempty(columns)
        value = columns{1};
    else
        value = '';
    end
end
