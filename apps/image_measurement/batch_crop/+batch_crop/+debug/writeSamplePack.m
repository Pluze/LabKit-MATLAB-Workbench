% Expected caller: app debug launch and unit tests. Input
% is a LabKit debug context. Output is a deterministic synthetic crop sample
% pack. Side effects: writes anonymous debug images and records a session
% manifest when available.
function pack = writeSamplePack(debugLog)
%WRITESAMPLEPACK Write Batch Crop debug image files.

    folders = debugFolders(debugLog, "batch_crop");
    imageFolder = fullfile(char(folders.sampleFolder), "images");
    ensureFolder(imageFolder);

    imageA = string(fullfile(imageFolder, "batch_crop_targets_a.png"));
    imageB = string(fullfile(imageFolder, "batch_crop_targets_b.png"));
    edgePath = string(fullfile(imageFolder, "batch_crop_valid_small_target.png"));
    malformedPath = string(fullfile(imageFolder, "batch_crop_malformed_not_image.png"));
    imwrite(targetImage(0), char(imageA));
    imwrite(targetImage(1), char(imageB));
    imwrite(targetImage(2), char(edgePath));
    writeTextFile(malformedPath, "not an image payload" + newline);

    representativeFiles = [imageA; imageB];
    pack = struct( ...
        "sampleFolder", folders.sampleFolder, ...
        "outputFolder", folders.outputFolder, ...
        "representativeFiles", representativeFiles, ...
        "boundaryFiles", struct("validEdge", edgePath, "malformed", malformedPath));
    manifest = struct( ...
        "type", "labkit.debug.samplePack.v1", ...
        "app", "labkit_BatchImageCrop_app", ...
        "description", "Anonymous crop-target boundary image pack.", ...
        "inputs", struct( ...
            "representativeImages", representativeFiles, ...
            "validEdgeImage", edgePath, ...
            "malformedImage", malformedPath), ...
        "outputFolder", folders.outputFolder);
    pack.manifest = manifest;
    recordManifest(debugLog, manifest);
end

function image = targetImage(variant)
    [x, y] = meshgrid(1:340, 1:260);
    base = 0.52 + 0.10 .* sin(0.05 .* x) + 0.07 .* sin(0.08 .* y);
    centers = [118 132; 230 150; 175 82];
    if variant == 1
        centers = centers + [16 -8; -12 10; 8 12];
    elseif variant == 2
        centers = [170 130; 190 145; 205 118];
    end
    image = repmat(base, 1, 1, 3);
    for k = 1:size(centers, 1)
        r = hypot(x - centers(k, 1), y - centers(k, 2));
        ring = r > 14 & r < 20;
        core = r < 8;
        image(:, :, 1) = image(:, :, 1) + 0.24 .* ring + 0.10 .* core;
        image(:, :, 2) = image(:, :, 2) + 0.18 .* ring + 0.05 .* core;
        image(:, :, 3) = image(:, :, 3) + 0.05 .* ring;
    end
    scaleCue = x > 42 & x < 112 & y > 226 & y < 232;
    image = image + 0.30 .* scaleCue;
    image = uint8(round(255 .* min(max(image, 0), 1)));
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

function writeTextFile(filepath, text)
    fid = fopen(char(filepath), "w", "n", "UTF-8");
    if fid < 0
        error("batch_crop:debug:SampleWriteFailed", ...
            "Could not write debug sample file: %s.", filepath);
    end
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", char(text));
end

function ensureFolder(folder)
    if exist(char(folder), "dir") ~= 7
        mkdir(char(folder));
    end
end
