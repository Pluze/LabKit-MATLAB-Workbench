% Expected caller: rhs_preview.run. Output is a user-selected protocol JSON
% output path, or "" when canceled. Side effect is a standard save dialog.
function outputPath = promptProtocolOutput(defaultFolder)
%PROMPTPROTOCOLOUTPUT Prompt for a protocol JSON destination.

    if nargin < 1 || strlength(string(defaultFolder)) == 0
        defaultFolder = tempdir;
    end
    [file, folder] = uiputfile({'*.json', 'Protocol JSON'}, ...
        'Save RHS protocol', fullfile(char(defaultFolder), 'rhs_protocol_draft.json'));
    if isequal(file, 0) || isequal(folder, 0)
        outputPath = "";
    else
        outputPath = string(fullfile(folder, file));
    end
end
