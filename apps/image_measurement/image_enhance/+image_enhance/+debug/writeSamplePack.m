% Expected caller: image_enhance.run during debug launch and unit tests.
% Input is a LabKit debug context. Output is a deterministic synthetic image
% enhancement sample pack. Side effects: writes anonymous debug images and
% records a session manifest when available.
function pack = writeSamplePack(debugLog)
%WRITESAMPLEPACK Write Image Enhance debug image files.

    folders = debugFolders(debugLog, "image_enhance");
    imageFolder = fullfile(char(folders.sampleFolder), "images");
    ensureFolder(imageFolder);

    sourceA = string(fullfile(imageFolder, "enhance_source_uneven_illumination.png"));
    sourceB = string(fullfile(imageFolder, "enhance_source_color_cast.png"));
    edgePath = string(fullfile(imageFolder, "enhance_valid_low_contrast_16bit.tif"));
    malformedPath = string(fullfile(imageFolder, "enhance_malformed_not_image.png"));

    imwrite(toUint8(sceneImage("uneven")), char(sourceA));
    imwrite(toUint8(sceneImage("colorCast")), char(sourceB));
    imwrite(uint16(round(65535 .* lowContrastScene())), char(edgePath));
    writeTextFile(malformedPath, "not an image payload" + newline);

    representativeFiles = [sourceA; sourceB];
    pack = struct( ...
        "sampleFolder", folders.sampleFolder, ...
        "outputFolder", folders.outputFolder, ...
        "representativeFiles", representativeFiles, ...
        "boundaryFiles", struct("validEdge", edgePath, "malformed", malformedPath));
    manifest = struct( ...
        "type", "labkit.debug.samplePack.v1", ...
        "app", "labkit_ImageEnhance_app", ...
        "description", "Anonymous detailed image-enhancement boundary pack.", ...
        "inputs", struct( ...
            "representativeImages", representativeFiles, ...
            "validEdgeImage", edgePath, ...
            "malformedImage", malformedPath), ...
        "outputFolder", folders.outputFolder);
    pack.manifest = manifest;
    recordManifest(debugLog, manifest);
end

function image = sceneImage(kind)
    [x, y] = meshgrid(linspace(-1, 1, 320), linspace(-1, 1, 240));
    illumination = 0.58 + 0.22 .* x - 0.15 .* y + 0.08 .* sin(4 .* x);
    fibers = 0.09 .* sin(42 .* x + 12 .* y) + 0.05 .* sin(35 .* y);
    inclusions = exp(-((x + 0.42).^2 + (y - 0.22).^2) ./ 0.010) + ...
        0.7 .* exp(-((x - 0.20).^2 + (y + 0.28).^2) ./ 0.018);
    neutralPatch = double(abs(x - 0.62) < 0.16 & abs(y + 0.55) < 0.10);
    base = min(max(illumination + fibers + 0.22 .* inclusions, 0), 1);
    image = repmat(base, 1, 1, 3);
    image = image .* (1 - 0.35 .* neutralPatch) + 0.72 .* neutralPatch;
    if kind == "colorCast"
        image(:, :, 1) = min(image(:, :, 1) .* 1.18, 1);
        image(:, :, 2) = min(image(:, :, 2) .* 1.02, 1);
        image(:, :, 3) = image(:, :, 3) .* 0.78;
    else
        image(:, :, 2) = min(image(:, :, 2) .* 1.05, 1);
        image(:, :, 3) = image(:, :, 3) .* 0.90;
    end
end

function image = lowContrastScene()
    [x, y] = meshgrid(linspace(0, 1, 220), linspace(0, 1, 160));
    gray = 0.48 + 0.025 .* sin(2 .* pi .* 8 .* x) + 0.018 .* y;
    image = min(max(repmat(gray, 1, 1, 3), 0), 1);
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
        error("image_enhance:debug:SampleWriteFailed", ...
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
