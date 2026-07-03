% Expected caller: response_review_stats.run. Inputs are a metrics table and
% target CSV path. Output is the written path. Side effect is one CSV write.
function outputPath = writeMetricsCsv(metrics, outputPath)
%WRITEMETRICSCSV Write review/stat metrics as CSV.

    outputPath = string(outputPath);
    if strlength(outputPath) == 0
        error("response_review_stats:InvalidOutput", ...
            "Metrics export requires an output path.");
    end
    writetable(metrics, char(outputPath));
end
