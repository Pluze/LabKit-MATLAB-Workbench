% Expected caller: flir_thermal.run during debug launch and unit tests. Input
% is a LabKit debug context. Output is a deterministic synthetic radiometric
% JPEG-like sample pack. Side effects: writes anonymous debug files and records
% a session manifest when available.
function pack = writeSamplePack(debugLog)
%WRITESAMPLEPACK Write FLIR Thermal debug radiometric files.

    folders = debugFolders(debugLog, "flir_thermal");
    sampleFolder = fullfile(char(folders.sampleFolder), "flir_thermal");
    ensureFolder(sampleFolder);

    warmPath = string(fullfile(sampleFolder, "flir_representative_gradient_debug.jpg"));
    coolPath = string(fullfile(sampleFolder, "flir_representative_cool_spot_debug.jpg"));
    edgePath = string(fullfile(sampleFolder, "flir_valid_low_contrast_debug.jpg"));
    malformedPath = string(fullfile(sampleFolder, "flir_malformed_plain_jpeg_debug.jpg"));

    writeSyntheticRjpeg(warmPath, syntheticRaw(96, 128, 18300, 900), struct( ...
        "emissivity", 0.96, "reflectedTemperatureC", 22, ...
        "atmosphericTemperatureC", 21, "objectDistanceM", 0.32, ...
        "relativeHumidity", 0.48));
    writeSyntheticRjpeg(coolPath, syntheticRaw(96, 128, 17900, -650), struct( ...
        "emissivity", 0.93, "reflectedTemperatureC", 20, ...
        "atmosphericTemperatureC", 20, "objectDistanceM", 0.45, ...
        "relativeHumidity", 0.55));
    writeSyntheticRjpeg(edgePath, syntheticRaw(24, 32, 18100, 35), struct( ...
        "emissivity", 1, "reflectedTemperatureC", 20, ...
        "atmosphericTemperatureC", 20, "objectDistanceM", 1, ...
        "relativeHumidity", 0.50));
    imwrite(uint8(repmat(linspace(30, 210, 96), 64, 1)), char(malformedPath));

    representative = [warmPath; coolPath];
    manifest = struct( ...
        "type", "labkit.debug.samplePack.v1", ...
        "app", "labkit_FLIRThermal_app", ...
        "description", "Anonymous FLIR radiometric JPEG-like boundary pack for debug launch.", ...
        "sampleFolder", string(sampleFolder), ...
        "outputFolder", folders.outputFolder, ...
        "representativeFiles", representative, ...
        "boundaryFiles", struct("validEdgeLowContrast", edgePath, "malformedPlainJpeg", malformedPath));
    recordManifest(debugLog, manifest);
    pack = manifest;
end

function raw = syntheticRaw(h, w, base, delta)
    [x, y] = meshgrid(linspace(-1, 1, w), linspace(-1, 1, h));
    gradient = delta .* (0.45 .* x + 0.30 .* y);
    spot = 0.65 .* delta .* exp(-((x - 0.22) ./ 0.28).^2 - ((y + 0.12) ./ 0.22).^2);
    texture = 42 .* sin(9 .* x) .* cos(7 .* y);
    raw = uint16(round(base + gradient + spot + texture));
end

function writeSyntheticRjpeg(filepath, raw, opts)
    calibration = defaultCalibration(opts);
    cameraBytes = cameraInfoBytes(size(raw, 2), size(raw, 1), calibration);
    pngBytes = rawPngBytes(raw);
    rawRecordBytes = [zeros(1, 40, "uint8"), pngBytes];
    block = flirBlock(cameraBytes, rawRecordBytes);
    jpegBytes = jpegWrapper(block);

    fid = fopen(char(filepath), "w");
    if fid < 0
        error("flir_thermal:debug:SampleWriteFailed", ...
            "Could not write debug sample file: %s.", filepath);
    end
    cleaner = onCleanup(@() fclose(fid));
    fwrite(fid, jpegBytes, "uint8");
end

function calibration = defaultCalibration(opts)
    calibration = struct( ...
        "Emissivity", double(optionValue(opts, "emissivity", 1)), ...
        "ObjectDistanceM", double(optionValue(opts, "objectDistanceM", 1)), ...
        "ReflectedApparentTemperatureC", double(optionValue(opts, "reflectedTemperatureC", 20)), ...
        "AtmosphericTemperatureC", double(optionValue(opts, "atmosphericTemperatureC", 20)), ...
        "IRWindowTemperatureC", 20, ...
        "IRWindowTransmission", 1, ...
        "RelativeHumidity", double(optionValue(opts, "relativeHumidity", 0.5)), ...
        "PlanckR1", 15896.4, ...
        "PlanckB", 1415.8, ...
        "PlanckF", 1, ...
        "AtmosphericTransAlpha1", 0.006569, ...
        "AtmosphericTransAlpha2", 0.01262, ...
        "AtmosphericTransBeta1", -0.002276, ...
        "AtmosphericTransBeta2", -0.00667, ...
        "AtmosphericTransX", 1.9, ...
        "CameraTemperatureRangeMaxC", 120, ...
        "CameraTemperatureRangeMinC", -20, ...
        "PlanckO", -4991, ...
        "PlanckR2", 0.0114916);
end

function bytes = cameraInfoBytes(width, height, calibration)
    base = 9;
    bytes = zeros(1, base + hex2dec("30c") + 3, "uint8");
    putU16le(base + hex2dec("00"), 2);
    putU16le(base + hex2dec("02"), width);
    putU16le(base + hex2dec("04"), height);
    putF32le(base + hex2dec("20"), calibration.Emissivity);
    putF32le(base + hex2dec("24"), calibration.ObjectDistanceM);
    putF32le(base + hex2dec("28"), calibration.ReflectedApparentTemperatureC + 273.15);
    putF32le(base + hex2dec("2c"), calibration.AtmosphericTemperatureC + 273.15);
    putF32le(base + hex2dec("30"), calibration.IRWindowTemperatureC + 273.15);
    putF32le(base + hex2dec("34"), calibration.IRWindowTransmission);
    putF32le(base + hex2dec("3c"), calibration.RelativeHumidity);
    putF32le(base + hex2dec("58"), calibration.PlanckR1);
    putF32le(base + hex2dec("5c"), calibration.PlanckB);
    putF32le(base + hex2dec("60"), calibration.PlanckF);
    putF32le(base + hex2dec("70"), calibration.AtmosphericTransAlpha1);
    putF32le(base + hex2dec("74"), calibration.AtmosphericTransAlpha2);
    putF32le(base + hex2dec("78"), calibration.AtmosphericTransBeta1);
    putF32le(base + hex2dec("7c"), calibration.AtmosphericTransBeta2);
    putF32le(base + hex2dec("80"), calibration.AtmosphericTransX);
    putF32le(base + hex2dec("90"), calibration.CameraTemperatureRangeMaxC + 273.15);
    putF32le(base + hex2dec("94"), calibration.CameraTemperatureRangeMinC + 273.15);
    putString(base + hex2dec("d4"), "DEVICE", 32);
    putString(base + hex2dec("114"), "debug", 16);
    putI32le(base + hex2dec("308"), calibration.PlanckO);
    putF32le(base + hex2dec("30c"), calibration.PlanckR2);

    function putU16le(index, value)
        bytes(index:index + 1) = typecast(uint16(value), "uint8");
    end

    function putI32le(index, value)
        bytes(index:index + 3) = typecast(int32(value), "uint8");
    end

    function putF32le(index, value)
        bytes(index:index + 3) = typecast(single(value), "uint8");
    end

    function putString(index, text, count)
        raw = uint8(char(string(text)));
        raw = raw(1:min(numel(raw), count));
        bytes(index:index + numel(raw) - 1) = raw;
    end
end

function bytes = rawPngBytes(raw)
    path = [tempname '.png'];
    imwrite(raw, char(path));
    fid = fopen(char(path), "r");
    if fid < 0
        error("flir_thermal:debug:SampleWriteFailed", ...
            "Could not read temporary thermal PNG payload.");
    end
    bytes = fread(fid, inf, "*uint8").';
    fclose(fid);
    deleteIfExists(path);
end

function block = flirBlock(cameraBytes, rawRecordBytes)
    directoryOffset = 64;
    recordCount = 2;
    entryLength = 32;
    dataOffset = directoryOffset + recordCount * entryLength;
    cameraOffset = dataOffset;
    rawOffset = cameraOffset + numel(cameraBytes);
    blockLength = rawOffset + numel(rawRecordBytes);

    block = zeros(1, blockLength, "uint8");
    block(1:5) = uint8(['FLIR' 0]);
    block(9:12) = uint8(['FFF' 0]);
    block = putU32be(block, 33, directoryOffset);
    block = putU32be(block, 37, recordCount);
    writeDirectoryEntry(65, 32, cameraOffset, numel(cameraBytes));
    writeDirectoryEntry(97, 1, rawOffset, numel(rawRecordBytes));
    block(cameraOffset + 1:cameraOffset + numel(cameraBytes)) = cameraBytes;
    block(rawOffset + 1:rawOffset + numel(rawRecordBytes)) = rawRecordBytes;

    function writeDirectoryEntry(startIndex, recordType, recordOffset, recordLength)
        block = putU16be(block, startIndex + 8, recordType);
        block = putU32be(block, startIndex + 20, recordOffset);
        block = putU32be(block, startIndex + 24, recordLength);
    end
end

function bytes = jpegWrapper(block)
    segmentLength = numel(block) + 2;
    if segmentLength > 65535
        error("flir_thermal:debug:SampleTooLarge", ...
            "Synthetic FLIR APP1 segment is too large.");
    end
    bytes = [uint8([255 216 255 225]), ...
        uint8([floor(segmentLength / 256), mod(segmentLength, 256)]), ...
        block, uint8([255 217])];
end

function bytes = putU16be(bytes, index, value)
    value = uint16(value);
    bytes(index:index + 1) = uint8([bitshift(value, -8), bitand(value, 255)]);
end

function bytes = putU32be(bytes, index, value)
    value = uint32(value);
    bytes(index:index + 3) = uint8([bitshift(value, -24), ...
        bitand(bitshift(value, -16), 255), bitand(bitshift(value, -8), 255), ...
        bitand(value, 255)]);
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

function value = optionValue(opts, fieldName, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, fieldName)
        value = opts.(fieldName);
    end
end

function ensureFolder(folder)
    if exist(char(folder), "dir") ~= 7
        mkdir(char(folder));
    end
end

function deleteIfExists(filepath)
    if isfile(filepath)
        delete(filepath);
    end
end
