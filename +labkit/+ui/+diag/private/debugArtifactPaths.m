% Expected caller: labkit.ui.diag.createContext. Inputs are debug opts and
% log path. Output is an app-neutral debug artifact path struct. Side effects:
% creates artifact, sample, and output folders when enabled.
function paths = debugArtifactPaths(opts, logFile, enabled)
    artifactFolder = string(optionValue(opts, 'artifactFolder', ...
        defaultArtifactFolder(logFile)));
    sampleFolder = string(optionValue(opts, 'sampleFolder', ...
        defaultSubfolder(artifactFolder, "samples")));
    outputFolder = string(optionValue(opts, 'outputFolder', ...
        defaultSubfolder(artifactFolder, "outputs")));
    manifestFile = string(optionValue(opts, 'manifestFile', ...
        defaultManifestFile(artifactFolder)));

    if enabled
        ensureDirectory(artifactFolder);
        ensureDirectory(sampleFolder);
        ensureDirectory(outputFolder);
    end

    paths = struct( ...
        "artifactFolder", artifactFolder, ...
        "sampleFolder", sampleFolder, ...
        "outputFolder", outputFolder, ...
        "manifestFile", manifestFile);
end

function folder = defaultArtifactFolder(logFile)
    logFile = string(logFile);
    if strlength(logFile) == 0
        folder = "";
        return;
    end
    folder = string(fileparts(char(logFile)));
end

function folder = defaultSubfolder(parentFolder, name)
    parentFolder = string(parentFolder);
    if strlength(parentFolder) == 0
        folder = "";
        return;
    end
    folder = string(fullfile(char(parentFolder), char(string(name))));
end

function filepath = defaultManifestFile(artifactFolder)
    artifactFolder = string(artifactFolder);
    if strlength(artifactFolder) == 0
        filepath = "";
        return;
    end
    filepath = string(fullfile(char(artifactFolder), "manifest.json"));
end

function ensureDirectory(folder)
    folder = string(folder);
    if strlength(folder) == 0
        return;
    end
    if exist(char(folder), "dir") ~= 7
        mkdir(char(folder));
    end
end

function value = optionValue(opts, fieldName, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, fieldName)
        value = opts.(fieldName);
    end
end
