% Expected caller: rhs_preview.run. Output is a user-selected filter JSON
% output path, or "" when canceled. Side effect is a standard save dialog.
function outputPath = promptFilterRecordOutput()
%PROMPTFILTERRECORDOUTPUT Prompt for a filter-record JSON destination.

    [file, folder] = uiputfile({'*.json', 'Filter JSON'}, ...
        'Save RHS filter record', 'rhs_filter_record.json');
    if isequal(file, 0) || isequal(folder, 0)
        outputPath = "";
    else
        outputPath = string(fullfile(folder, file));
    end
end
