% Expected caller: image_match.definition during debug launch and unit tests. Input
% is a LabKit debug context. Output is a deterministic synthetic reference
% matching sample pack. Side effects: writes anonymous debug images and
% records a session manifest when available.
function pack = writeSamplePack(debugLog)
%WRITESAMPLEPACK Write Image Match debug image files.

    folders = debugFolders(debugLog, "image_match");
    imageFolder = fullfile(char(folders.sampleFolder), "images");
    ensureFolder(imageFolder);

    referencePath = string(fullfile(imageFolder, "match_reference.png"));
    sourceWarmPath = string(fullfile(imageFolder, "match_source_warm_shift.png"));
    sourceDimPath = string(fullfile(imageFolder, "match_source_dim_shift.png"));
    edgePath = string(fullfile(imageFolder, "match_valid_size_mismatch.png"));
    malformedPath = string(fullfile(imageFolder, "match_malformed_not_image.png"));

    reference = sceneImage("reference", [240 320]);
    imwrite(toUint8(reference), char(referencePath));
    imwrite(toUint8(sceneImage("warm", [240 320])), char(sourceWarmPath));
    imwrite(toUint8(sceneImage("dim", [240 320])), char(sourceDimPath));
    imwrite(toUint8(sceneImage("warm", [180 260])), char(edgePath));
    writeTextFile(malformedPath, "not an image payload" + newline);

    representativeFiles = [sourceWarmPath; sourceDimPath];
    pack = struct( ...
        "sampleFolder", folders.sampleFolder, ...
        "outputFolder", folders.outputFolder, ...
        "referenceFile", referencePath, ...
        "representativeFiles", representativeFiles, ...
        "boundaryFiles", struct("validEdge", edgePath, "malformed", malformedPath));
    manifest = struct( ...
        "type", "labkit.debug.samplePack.v1", ...
        "app", "labkit_ImageMatch_app", ...
        "description", "Anonymous reference-match boundary image pack.", ...
        "inputs", struct( ...
            "referenceImage", referencePath, ...
            "representativeSourceImages", representativeFiles, ...
            "validEdgeImage", edgePath, ...
            "malformedImage", malformedPath), ...
        "outputFolder", folders.outputFolder);
    pack.manifest = manifest;
    recordManifest(debugLog, manifest);
end

function image = sceneImage(kind, dims)
    rows = dims(1);
    cols = dims(2);
    [x, y] = meshgrid(linspace(-1, 1, cols), linspace(-1, 1, rows));
    base = 0.55 + 0.15 .* x - 0.08 .* y + 0.08 .* sin(30 .* x + 6 .* y);
    target = exp(-((x + 0.28).^2 + (y - 0.18).^2) ./ 0.015) + ...
        0.7 .* exp(-((x - 0.35).^2 + (y + 0.22).^2) ./ 0.020);
    image = repmat(min(max(base + 0.20 .* target, 0), 1), 1, 1, 3);
    image(:, :, 1) = image(:, :, 1) + 0.08 .* target;
    image(:, :, 2) = image(:, :, 2) + 0.04 .* sin(4 .* y);
    image(:, :, 3) = image(:, :, 3) .* 0.92;
    switch kind
        case "warm"
            image(:, :, 1) = min(image(:, :, 1) .* 1.20 + 0.04, 1);
            image(:, :, 3) = image(:, :, 3) .* 0.78;
        case "dim"
            image = image .* 0.72 + 0.08;
            image(:, :, 2) = min(image(:, :, 2) .* 1.12, 1);
    end
    image = min(max(image, 0), 1);
end

function image = toUint8(image)
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
        error("image_match:debug:SampleWriteFailed", ...
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
