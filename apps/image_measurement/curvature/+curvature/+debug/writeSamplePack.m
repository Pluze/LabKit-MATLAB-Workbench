% Expected caller: curvature.definitionActions during debug launch and unit tests. Input
% is a LabKit debug context. Output is a deterministic synthetic curvature
% image sample pack. Side effects: writes anonymous debug images and records
% a session manifest when available.
function pack = writeSamplePack(debugLog)
%WRITESAMPLEPACK Write Curvature debug image files.

    folders = debugFolders(debugLog, "curvature");
    imageFolder = fullfile(char(folders.sampleFolder), "images");
    ensureFolder(imageFolder);

    arcPath = string(fullfile(imageFolder, "curvature_arc_feature.png"));
    edgePath = string(fullfile(imageFolder, "curvature_valid_low_contrast_arc.png"));
    malformedPath = string(fullfile(imageFolder, "curvature_malformed_not_image.png"));
    imwrite(arcImage(false), char(arcPath));
    imwrite(arcImage(true), char(edgePath));
    writeTextFile(malformedPath, "not an image payload" + newline);

    pack = struct( ...
        "sampleFolder", folders.sampleFolder, ...
        "outputFolder", folders.outputFolder, ...
        "representativeFiles", arcPath, ...
        "boundaryFiles", struct("validEdge", edgePath, "malformed", malformedPath));
    manifest = struct( ...
        "type", "labkit.debug.samplePack.v1", ...
        "app", "labkit_CurvatureMeasurement_app", ...
        "description", "Anonymous arc-feature boundary image pack.", ...
        "inputs", struct( ...
            "representativeImage", arcPath, ...
            "validEdgeImage", edgePath, ...
            "malformedImage", malformedPath), ...
        "outputFolder", folders.outputFolder);
    pack.manifest = manifest;
    recordManifest(debugLog, manifest);
end

function image = arcImage(lowContrast)
    [x, y] = meshgrid(1:360, 1:260);
    cx = 180;
    cy = 255;
    radius = 165;
    distance = abs(hypot(x - cx, y - cy) - radius);
    arcMask = distance < 4 & y < 220 & x > 55 & x < 310;
    texture = 0.46 + 0.10 .* sin(0.08 .* x + 0.03 .* y) + ...
        0.05 .* sin(0.20 .* y);
    image = repmat(texture, 1, 1, 3);
    if lowContrast
        image = image + 0.06 .* arcMask;
    else
        image(:, :, 1) = image(:, :, 1) + 0.38 .* arcMask;
        image(:, :, 2) = image(:, :, 2) + 0.30 .* arcMask;
        image(:, :, 3) = image(:, :, 3) + 0.08 .* arcMask;
    end
    scaleCue = x > 250 & x < 315 & y > 222 & y < 228;
    image = image + 0.25 .* scaleCue;
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
        error("curvature:debug:SampleWriteFailed", ...
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
