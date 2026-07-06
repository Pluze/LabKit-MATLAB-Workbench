% Expected caller: figure_studio.definitionActions during debug launch and
% unit guardrails. Input is a LabKit debug context. Output is a deterministic
% synthetic FIG sample pack. Side effects: writes anonymous debug FIG files
% and records a session manifest when available.
function pack = writeSamplePack(debugLog)
%WRITESAMPLEPACK Write Figure Studio debug FIG files.

    folders = debugFolders(debugLog, "figure_studio");
    figPath = string(fullfile(folders.sampleFolder, "figure_studio_debug.fig"));
    writeDebugFigure(figPath);

    pack = struct( ...
        "sampleFolder", folders.sampleFolder, ...
        "outputFolder", folders.outputFolder, ...
        "representativeFiles", figPath, ...
        "boundaryFiles", struct());
    manifest = struct( ...
        "type", "labkit.debug.samplePack.v1", ...
        "app", "labkit_FigureStudio_app", ...
        "description", "Anonymous MATLAB FIG sample for Figure Studio debug launch.", ...
        "inputs", struct("representativeFig", figPath), ...
        "outputFolder", folders.outputFolder);
    pack.manifest = manifest;
    recordManifest(debugLog, manifest);
end

function writeDebugFigure(filepath)
    fig = figure('Visible', 'off', 'Color', 'w', 'Units', 'pixels', ...
        'Position', [100 100 720 540]);
    cleaner = onCleanup(@() delete(fig));
    ax = axes('Parent', fig);
    x = linspace(0, 40, 80);
    hold(ax, 'on');
    plot(ax, x, 0.04 .* x, 'LineWidth', 3, 'DisplayName', '0%');
    plot(ax, x, 0.05 .* x, 'LineWidth', 3, 'DisplayName', '0.1%');
    xline(ax, 20, 'R', 'Color', [0.85 0.10 0.10], ...
        'LineStyle', '--', 'LineWidth', 1.5);
    hold(ax, 'off');
    ax.FontName = 'Arial';
    ax.FontSize = 36;
    ax.LineWidth = 3;
    ax.Box = 'on';
    xlabel(ax, 'Strain (%)');
    ylabel(ax, 'Stress (MPa)');
    title(ax, 'Debug Figure');
    legend(ax, 'Location', 'northwest', 'Box', 'off');
    savefig(fig, char(filepath));
end

function folders = debugFolders(debugLog, appToken)
    sampleFolder = ""; outputFolder = "";
    if isstruct(debugLog)
        if isfield(debugLog, "sampleFolder"), sampleFolder = string(debugLog.sampleFolder); end
        if isfield(debugLog, "outputFolder"), outputFolder = string(debugLog.outputFolder); end
    end
    if strlength(sampleFolder) == 0
        sampleFolder = string(fullfile(tempdir, "LabKit-MATLAB-Workbench", ...
            "debug", appToken, "samples"));
    end
    if strlength(outputFolder) == 0
        outputFolder = string(fullfile(tempdir, "LabKit-MATLAB-Workbench", ...
            "debug", appToken, "outputs"));
    end
    ensureFolder(sampleFolder);
    ensureFolder(outputFolder);
    folders = struct("sampleFolder", sampleFolder, "outputFolder", outputFolder);
end

function recordManifest(debugLog, manifest)
    if isstruct(debugLog) && isfield(debugLog, "recordArtifacts") && ...
            isa(debugLog.recordArtifacts, "function_handle")
        debugLog.recordArtifacts(manifest);
    end
end

function ensureFolder(folder)
    if exist(char(folder), "dir") ~= 7
        mkdir(char(folder));
    end
end
