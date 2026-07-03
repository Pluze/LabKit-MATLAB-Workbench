% Expected caller: rhs_preview.actions.table. Input is an app state struct and target
% JSON path. Output is the written path. Side effect is one protocol JSON.
function outputPath = writeProtocolJson(S, outputPath)
%WRITEPROTOCOLJSON Write a Preview-authored protocol draft.

    outputPath = string(outputPath);
    if ~isscalar(outputPath) || strlength(outputPath) == 0
        error("rhs_preview:InvalidOutput", ...
            "Protocol export requires one output JSON path.");
    end

    payload = rhs_preview.export.protocolJsonStruct(S);
    text = jsonencode(payload, "PrettyPrint", true);
    fid = fopen(char(outputPath), "w");
    if fid < 0
        error("rhs_preview:WriteFailed", "Could not write protocol JSON.");
    end
    cleaner = onCleanup(@() fclose(fid));
    fwrite(fid, text, "char");
end
