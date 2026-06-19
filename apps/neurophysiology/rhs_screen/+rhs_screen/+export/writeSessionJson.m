% Expected caller: rhs_screen.run. Input is a screening session and target
% JSON path. Output is the written path. Side effect is one JSON file write.
function outputPath = writeSessionJson(session, outputPath)
%WRITESESSIONJSON Write a lightweight RHS screening session.

    outputPath = string(outputPath);
    if ~isscalar(outputPath) || strlength(outputPath) == 0
        error("rhs_screen:InvalidOutput", ...
            "Session export requires one output JSON path.");
    end

    payload = rhs_screen.export.sessionJsonStruct(session);
    text = jsonencode(payload, "PrettyPrint", true);
    fid = fopen(char(outputPath), "w");
    if fid < 0
        error("rhs_screen:WriteFailed", "Could not write session JSON.");
    end
    cleaner = onCleanup(@() fclose(fid));
    fwrite(fid, text, "char");
end
