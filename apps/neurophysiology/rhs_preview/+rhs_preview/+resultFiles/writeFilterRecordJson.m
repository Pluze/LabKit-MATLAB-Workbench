% Expected caller: rhs_preview.definitionActions. Input is app state and target JSON path.
% Output is the written path. Side effect is one manual filter record JSON.
function outputPath = writeFilterRecordJson(S, outputPath)
%WRITEFILTERRECORDJSON Write a Preview-authored RHS filter record.

    outputPath = string(outputPath);
    if ~isscalar(outputPath) || strlength(outputPath) == 0
        error("rhs_preview:InvalidOutput", ...
            "Filter export requires one output JSON path.");
    end

    payload = rhs_preview.resultFiles.filterRecordJsonStruct(S);
    text = jsonencode(payload, "PrettyPrint", true);
    fid = fopen(char(outputPath), "w");
    if fid < 0
        error("rhs_preview:WriteFailed", "Could not write filter JSON.");
    end
    cleaner = onCleanup(@() fclose(fid));
    fwrite(fid, text, "char");
end
