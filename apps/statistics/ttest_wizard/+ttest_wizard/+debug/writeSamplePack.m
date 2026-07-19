% App debug-sample writer; returns synthetic paths and writes only temporary artifacts.
function pack = writeSamplePack(debugLog)
%WRITESAMPLEPACK Write an anonymous four-group CSV for debug launch.
%
% Expected caller: Runtime DebugSample lifecycle and App isolation tests.
% debugLog is the injected debug context when available. The output identifies
% one representative synthetic CSV and an output folder. Side effects are
% limited to ignored temporary debug artifacts.

    sampleFolder = "";
    outputFolder = "";
    if isstruct(debugLog)
        if isfield(debugLog, 'sampleFolder')
            sampleFolder = string(debugLog.sampleFolder);
        end
        if isfield(debugLog, 'outputFolder')
            outputFolder = string(debugLog.outputFolder);
        end
    end
    if strlength(sampleFolder) == 0
        sampleFolder = string(fullfile(tempdir, ...
            "LabKit-MATLAB-Workbench", "debug", ...
            "ttest_wizard", "samples"));
    end
    if strlength(outputFolder) == 0
        outputFolder = string(fullfile(tempdir, ...
            "LabKit-MATLAB-Workbench", "debug", ...
            "ttest_wizard", "outputs"));
    end
    ensureFolder(sampleFolder);
    ensureFolder(outputFolder);
    filepath = string(fullfile(sampleFolder, ...
        "synthetic_group_table.csv"));
    writecell({ ...
        'Reference', 'Treatment 1', 'Treatment 2', 'Treatment 3'; ...
        1.2, 1.7, 1.1, 1.5; ...
        1.4, 1.8, 1.2, 1.6; ...
        1.3, 2.0, 1.4, 1.5; ...
        1.5, 1.9, 1.3, 1.7}, filepath);
    pack = struct( ...
        "sampleFolder", sampleFolder, ...
        "outputFolder", outputFolder, ...
        "representativeFiles", filepath);
end

function ensureFolder(folder)
    if exist(char(folder), 'dir') ~= 7
        mkdir(char(folder));
    end
end
