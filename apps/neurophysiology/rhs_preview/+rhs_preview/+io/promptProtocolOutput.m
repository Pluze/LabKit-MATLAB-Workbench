% Expected caller: rhs_preview.actions.table. Output is a user-selected protocol JSON
% output path, or "" when canceled. Side effect is a standard save dialog.
function outputPath = promptProtocolOutput(defaultFolder)
%PROMPTPROTOCOLOUTPUT Prompt for a protocol JSON destination.

    if nargin < 1 || strlength(string(defaultFolder)) == 0
        defaultFolder = tempdir;
    end
    [outputPath, cancelled] = labkit.ui.app.promptOutputFile( ...
        {'*.json', 'Protocol JSON'}, 'Save RHS protocol', ...
        fullfile(char(defaultFolder), 'rhs_protocol_draft.json'));
    if cancelled
        outputPath = "";
    end
end
