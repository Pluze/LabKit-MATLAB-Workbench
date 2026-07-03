% Expected caller: rhs_preview.actions.table. Output is a user-selected filter JSON
% output path, or "" when canceled. Side effect is a standard save dialog.
function outputPath = promptFilterRecordOutput(defaultFolder)
%PROMPTFILTERRECORDOUTPUT Prompt for a filter-record JSON destination.

    if nargin < 1 || strlength(string(defaultFolder)) == 0
        defaultFolder = tempdir;
    end
    [outputPath, cancelled] = labkit.ui.app.promptOutputFile( ...
        {'*.json', 'Filter JSON'}, 'Save RHS filter record', ...
        fullfile(char(defaultFolder), 'rhs_filter_record.json'));
    if cancelled
        outputPath = "";
    end
end
