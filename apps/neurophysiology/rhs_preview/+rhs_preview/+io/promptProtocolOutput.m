% Expected caller: rhs_preview.run. Output is a user-selected protocol JSON
% output path, or "" when canceled. Side effect is a standard save dialog.
function outputPath = promptProtocolOutput()
%PROMPTPROTOCOLOUTPUT Prompt for a protocol JSON destination.

    [file, folder] = uiputfile({'*.json', 'Protocol JSON'}, ...
        'Save RHS protocol', 'rhs_protocol_draft.json');
    if isequal(file, 0) || isequal(folder, 0)
        outputPath = "";
    else
        outputPath = string(fullfile(folder, file));
    end
end
