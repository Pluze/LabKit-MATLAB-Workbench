% Expected caller: CSC UI refresh and tests. Inputs are an all-cycle CSC
% export table and selected display mode. Output is compact uitable data.

function data = cycleResultsTableData(results, mode)
%CYCLERESULTSTABLEDATA Build compact all-cycle CSC result table data.

    if isempty(results) || height(results) == 0
        data = cell(0, 6);
        return;
    end

    fields = modeFields(mode);
    data = cell(height(results), 6);
    for iRow = 1:height(results)
        data{iRow, 1} = cycleLabel(results, iRow);
        data{iRow, 2} = results.Rows(iRow);
        data{iRow, 3} = results.(fields.cv)(iRow);
        data{iRow, 4} = results.(fields.ct)(iRow);
        data{iRow, 5} = results.(fields.rel)(iRow);
        data{iRow, 6} = char(results.Status(iRow));
    end
end

function fields = modeFields(mode)
    choices = csc.userInterface.analysisChoices();
    switch char(string(mode))
        case char(choices.modes(2))
            fields = struct('cv', 'CSCcvCath_mCcm2', ...
                'ct', 'CSCctCath_mCcm2', ...
                'rel', 'RelativeDiffCath_pct');
        case char(choices.modes(3))
            fields = struct('cv', 'CSCcvAnod_mCcm2', ...
                'ct', 'CSCctAnod_mCcm2', ...
                'rel', 'RelativeDiffAnod_pct');
        otherwise
            fields = struct('cv', 'CSCcvFull_mCcm2', ...
                'ct', 'CSCctFull_mCcm2', ...
                'rel', 'RelativeDiffFull_pct');
    end
end

function label = cycleLabel(results, iRow)
    name = string(results.CurveName(iRow));
    if strlength(name) == 0
        label = sprintf('%d', results.CurveIndex(iRow));
    else
        label = sprintf('%d: %s', results.CurveIndex(iRow), char(name));
    end
end
