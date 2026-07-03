% Expected caller: dic_preprocess.actions.table during debug launch and unit tests.
% Input is a LabKit debug context. Output is a deterministic synthetic DIC
% image-pair sample pack. Side effects: writes anonymous debug images and
% records a session manifest when available.
function pack = writeSamplePack(debugLog)
%WRITESAMPLEPACK Write DIC preprocess debug image files.

    folders = debugFolders(debugLog, "dic_preprocess");
    sampleFolder = fullfile(char(folders.sampleFolder), "dic_preprocess");
    ensureFolder(sampleFolder);

    referencePath = string(fullfile(sampleFolder, "dic_reference_speckle_debug.png"));
    movingPath = string(fullfile(sampleFolder, "dic_moving_shifted_speckle_debug.png"));
    lowTexturePath = string(fullfile(sampleFolder, "dic_valid_low_texture_debug.png"));
    malformedPath = string(fullfile(sampleFolder, "dic_malformed_not_an_image.png"));

    ref = syntheticSpeckleImage(192, 256, 0, 0, 1);
    moving = syntheticSpeckleImage(192, 256, 4.2, -2.8, 0.96);
    lowTexture = uint8(round(255 .* min(1, max(0, 0.48 + 0.03 .* syntheticField(192, 256)))));

    imwrite(ref, char(referencePath));
    imwrite(moving, char(movingPath));
    imwrite(lowTexture, char(lowTexturePath));
    writeTextFile(malformedPath, ["not a png payload"; "boundary=malformed image"]);

    manifest = struct( ...
        "type", "labkit.debug.samplePack.v1", ...
        "app", "labkit_DICPreprocess_app", ...
        "description", "Anonymous DIC image-pair boundary pack for debug launch.", ...
        "sampleFolder", string(sampleFolder), ...
        "outputFolder", folders.outputFolder, ...
        "representativeFiles", struct("reference", referencePath, "moving", movingPath), ...
        "boundaryFiles", struct( ...
            "validEdgeLowTexture", lowTexturePath, ...
            "malformedImage", malformedPath));
    recordManifest(debugLog, manifest);

    pack = manifest;
    pack.referenceFile = referencePath;
    pack.movingFile = movingPath;
end

function img = syntheticSpeckleImage(h, w, shiftX, shiftY, gain)
    [x, y] = meshgrid(1:w, 1:h);
    base = 0.38 + 0.08 .* sin((x + shiftX) ./ 13) + 0.06 .* cos((y + shiftY) ./ 17);
    speckle = syntheticField(h, w);
    fibers = 0.10 .* sin((x .* 0.10) + (y .* 0.035) + shiftX .* 0.15);
    cue = exp(-(((x - 176 - shiftX) ./ 28).^2 + ((y - 86 - shiftY) ./ 10).^2));
    gray = gain .* (base + 0.16 .* speckle + fibers + 0.22 .* cue);
    img = uint8(round(255 .* min(1, max(0, gray))));
end

function field = syntheticField(h, w)
    [x, y] = meshgrid(1:w, 1:h);
    field = 0.42 .* sin(x ./ 3.7) .* cos(y ./ 5.1) + ...
        0.31 .* sin((x + 2 .* y) ./ 8.3) + ...
        0.21 .* cos((2 .* x - y) ./ 11.0);
end

function folders = debugFolders(debugLog, appToken)
    sampleFolder = "";
    outputFolder = "";
    if isstruct(debugLog)
        if isfield(debugLog, "sampleFolder"), sampleFolder = string(debugLog.sampleFolder); end
        if isfield(debugLog, "outputFolder"), outputFolder = string(debugLog.outputFolder); end
    end
    if strlength(sampleFolder) == 0
        sampleFolder = string(fullfile(tempdir, "LabKit-MATLAB-Workbench", "debug", appToken, "samples"));
    end
    if strlength(outputFolder) == 0
        outputFolder = string(fullfile(tempdir, "LabKit-MATLAB-Workbench", "debug", appToken, "outputs"));
    end
    ensureFolder(sampleFolder);
    ensureFolder(outputFolder);
    folders = struct("sampleFolder", sampleFolder, "outputFolder", outputFolder);
end

function recordManifest(debugLog, manifest)
    if isstruct(debugLog) && isfield(debugLog, "recordArtifacts") && isa(debugLog.recordArtifacts, "function_handle")
        debugLog.recordArtifacts(manifest);
    end
end

function writeTextFile(filepath, lines)
    fid = fopen(char(filepath), "w");
    if fid < 0
        error("dic_preprocess:debug:SampleWriteFailed", "Could not write debug sample file: %s.", filepath);
    end
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, "%s\n", lines);
end

function ensureFolder(folder)
    if exist(char(folder), "dir") ~= 7
        mkdir(char(folder));
    end
end
