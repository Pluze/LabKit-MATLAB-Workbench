function fixture = writeSyntheticFlirRjpegFixture(filepath, opts)
%WRITESYNTHETICFLIRRJPEGFIXTURE Write a cross-owner synthetic FLIR RJPEG fixture.
%
% Expected caller: thermal facade and FLIR app tests. Inputs are a
% destination path and optional struct fields raw, emissivity,
% reflectedTemperatureC, atmosphericTemperatureC, objectDistanceM, and
% relativeHumidity. Output describes the written raw matrix and calibration.
% Side effect is one anonymous radiometric JPEG-like file with no real sample
% data.

    if nargin < 2 || isempty(opts)
        opts = struct();
    end
    raw = uint16(optionValue(opts, "raw", ...
        [18000 18100 18200; 18300 18400 18500]));
    calibration = defaultCalibration(opts);
    cameraBytes = cameraInfoBytes(size(raw, 2), size(raw, 1), calibration);
    pngBytes = rawPngBytes(raw);
    rawRecordBytes = [zeros(1, 40, "uint8"), pngBytes];
    block = flirBlock(cameraBytes, rawRecordBytes);
    jpegBytes = jpegWrapper(block);

    ensureParentFolder(filepath);
    fid = fopen(char(filepath), "w");
    if fid < 0
        error("tests:flir:FixtureWriteFailed", ...
            "Could not create synthetic FLIR RJPEG fixture.");
    end
    cleaner = onCleanup(@() fclose(fid));
    fwrite(fid, jpegBytes, "uint8");

    fixture = struct( ...
        "path", string(filepath), ...
        "raw", double(raw), ...
        "calibration", calibration);
end

function calibration = defaultCalibration(opts)
    calibration = struct( ...
        "Emissivity", double(optionValue(opts, "emissivity", 1)), ...
        "ObjectDistanceM", double(optionValue(opts, "objectDistanceM", 1)), ...
        "ReflectedApparentTemperatureC", ...
        double(optionValue(opts, "reflectedTemperatureC", 20)), ...
        "AtmosphericTemperatureC", ...
        double(optionValue(opts, "atmosphericTemperatureC", 20)), ...
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
    putString(base + hex2dec("d4"), "Synthetic FLIR", 32);
    putString(base + hex2dec("114"), "test", 16);
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
        error("tests:flir:FixtureWriteFailed", ...
            "Could not read synthetic thermal PNG payload.");
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
        error("tests:flir:FixtureTooLarge", ...
            "Synthetic FLIR APP1 segment is too large.");
    end
    bytes = [ ...
        uint8([255 216 255 225]), ...
        uint8([floor(segmentLength / 256), mod(segmentLength, 256)]), ...
        block, ...
        uint8([255 217])];
end

function bytes = putU16be(bytes, index, value)
    value = uint16(value);
    bytes(index:index + 1) = uint8([bitshift(value, -8), bitand(value, 255)]);
end

function bytes = putU32be(bytes, index, value)
    value = uint32(value);
    bytes(index:index + 3) = uint8([ ...
        bitshift(value, -24), ...
        bitand(bitshift(value, -16), 255), ...
        bitand(bitshift(value, -8), 255), ...
        bitand(value, 255)]);
end

function ensureParentFolder(filepath)
    folder = fileparts(char(filepath));
    if strlength(string(folder)) > 0 && exist(folder, "dir") ~= 7
        mkdir(folder);
    end
end

function deleteIfExists(filepath)
    if isfile(filepath)
        delete(filepath);
    end
end

function value = optionValue(opts, fieldName, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, fieldName)
        value = opts.(fieldName);
    end
end
