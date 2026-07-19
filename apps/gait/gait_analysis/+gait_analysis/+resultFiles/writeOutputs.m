%WRITEOUTPUTS Write gait analysis CSV outputs.
% Expected caller: export callback and tests. Creates a frame table, step table,
% coordinate table, and summary table using the provided filename stem.
function outputs = writeOutputs(outputFolder, stem, result)
    outputFolder = string(outputFolder);
    stem = matlab.lang.makeValidName(char(string(stem)));
    if strlength(outputFolder) == 0
        error('labkit_GaitAnalysis_app:MissingOutputFolder', ...
            'Choose an output folder before exporting gait results.');
    end
    if ~result.ok
        error('labkit_GaitAnalysis_app:NoResultToExport', ...
            'Run gait analysis before exporting CSV files.');
    end
    if exist(outputFolder, "dir") ~= 7
        mkdir(outputFolder);
    end

    outputs = struct();
    outputs.frameCsv = fullfile(outputFolder, stem + "_frames.csv");
    outputs.coordinateCsv = fullfile(outputFolder, stem + "_coordinates.csv");
    outputs.stepCsv = fullfile(outputFolder, stem + "_steps.csv");
    outputs.summaryCsv = fullfile(outputFolder, stem + "_summary.csv");
    writetable(result.frameTable, outputs.frameCsv);
    writetable(result.coordinateTable, outputs.coordinateCsv);
    writetable(result.stepTable, outputs.stepCsv);
    writetable(result.summaryTable, outputs.summaryCsv);
end
