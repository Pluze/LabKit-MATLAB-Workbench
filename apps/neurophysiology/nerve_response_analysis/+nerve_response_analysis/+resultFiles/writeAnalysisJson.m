% Expected caller: nerve_response_analysis.resultFiles.exportAnalysis. Input is an analysis struct
% and target JSON path. Output is the written path. Side effect is one file.
function outputPath = writeAnalysisJson(analysis, outputPath)
%WRITEANALYSISJSON Write nerve-response analysis JSON.

    outputPath = string(outputPath);
    if strlength(outputPath) == 0
        error("nerve_response_analysis:InvalidOutput", ...
            "Analysis export requires an output path.");
    end
    payload = nerve_response_analysis.resultFiles.analysisJsonStruct(analysis);
    text = jsonencode(payload, "PrettyPrint", true);
    fid = fopen(char(outputPath), "w");
    if fid < 0
        error("nerve_response_analysis:WriteFailed", ...
            "Could not write analysis JSON.");
    end
    cleaner = onCleanup(@() fclose(fid));
    fwrite(fid, text, "char");
end
