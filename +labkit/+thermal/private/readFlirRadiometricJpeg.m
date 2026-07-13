% Expected caller: labkit.thermal.readFile. Inputs are one radiometric JPEG
% path and normalized thermal read options. Output is a thermal record with
% raw matrix, optional temperature matrix, and FLIR metadata. Side effects:
% reads source bytes and may use a temporary PNG file to decode embedded raw
% thermal images through MATLAB imread.
function record = readFlirRadiometricJpeg(path, opts)

    bytes = readBytes(path);
    block = findFlirBlock(bytes);
    directory = parseFffDirectory(block);
    rawRecord = selectRecord(directory, 1);
    rawBytes = recordBytes(block, rawRecord);

    cameraInfo = struct();
    cameraRecords = directory([directory.type] == 32);
    if ~isempty(cameraRecords)
        cameraBytes = recordBytes(block, cameraRecords(1));
        cameraInfo = parseCameraInfo(cameraBytes);
    end

    [raw, rawByteOrder] = decodeRawThermalImage(rawBytes, cameraInfo);
    [temperatureC, units, message, conversion] = ...
        convertTemperature(raw, cameraInfo, opts);
    [~, base, ext] = fileparts(char(path));

    metadata = struct();
    metadata.reader = "flir-rjpeg-fff";
    metadata.rawImageType = embeddedImageType(rawBytes);
    metadata.rawByteOrder = rawByteOrder;
    metadata.calibration = cameraInfo;
    metadata.temperatureConversion = conversion;
    metadata.records = directory;

    record = struct( ...
        'path', string(path), ...
        'name', string([base ext]), ...
        'format', "FLIR radiometric JPEG", ...
        'raw', raw, ...
        'temperatureC', temperatureC, ...
        'units', units, ...
        'metadata', metadata, ...
        'message', message);
end

function bytes = readBytes(path)
    fid = fopen(char(path), 'r');
    if fid < 0
        error('labkit:thermal:FileNotFound', ...
            'Thermal image file does not exist: %s', char(path));
    end
    cleaner = onCleanup(@() fclose(fid));
    bytes = fread(fid, inf, '*uint8').';
end

function block = findFlirBlock(bytes)
    markers = find(bytes(1:end - 1) == 255 & bytes(2:end) == 225);
    for k = 1:numel(markers)
        marker = markers(k);
        if marker + 4 > numel(bytes)
            continue;
        end
        segmentLength = readU16be(bytes, marker + 2);
        payloadStart = marker + 4;
        payloadEnd = min(numel(bytes), payloadStart + double(segmentLength) - 3);
        if payloadEnd < payloadStart
            continue;
        end
        payload = bytes(payloadStart:payloadEnd);
        if numel(payload) >= 12 && isequal(payload(1:5), uint8(['FLIR' 0]))
            block = payload;
            return;
        end
    end

    signature = uint8(['FLIR' 0]);
    starts = strfind(bytes, signature);
    if ~isempty(starts)
        block = bytes(starts(1):end);
        return;
    end

    error('labkit:thermal:FlirBlockNotFound', ...
        'No FLIR radiometric metadata block was found in the JPEG file.');
end

function directory = parseFffDirectory(block)
    if numel(block) < 64 || ~isequal(block(1:4), uint8('FLIR'))
        error('labkit:thermal:InvalidFlirBlock', ...
            'FLIR metadata block is too short or malformed.');
    end
    directoryOffset = double(readU32be(block, 33)) + 1;
    recordCount = double(readU32be(block, 37));
    entryLength = 32;
    if directoryOffset < 1 || recordCount < 1 || ...
            directoryOffset + entryLength * recordCount - 1 > numel(block)
        error('labkit:thermal:InvalidFlirDirectory', ...
            'FLIR FFF record directory is missing or out of range.');
    end

    template = struct('type', 0, 'subtype', 0, 'id', 0, ...
        'offset', 0, 'length', 0);
    directory = repmat(template, recordCount, 1);
    for k = 1:recordCount
        entryStart = directoryOffset + (k - 1) * entryLength;
        entry = block(entryStart:entryStart + entryLength - 1);
        directory(k) = struct( ...
            'type', readU16be(entry, 9), ...
            'subtype', readU16be(entry, 11), ...
            'id', readU32be(entry, 13), ...
            'offset', readU32be(entry, 21), ...
            'length', readU32be(entry, 25));
    end
end

function record = selectRecord(directory, type)
    matches = directory([directory.type] == type);
    if isempty(matches)
        error('labkit:thermal:RawThermalImageNotFound', ...
            'No FLIR RawThermalImage record was found.');
    end
    record = matches(1);
end

function bytes = recordBytes(block, record)
    first = double(record.offset) + 1;
    last = first + double(record.length) - 1;
    if first < 1 || last > numel(block) || last < first
        error('labkit:thermal:InvalidFlirRecord', ...
            'FLIR record payload is outside the metadata block.');
    end
    bytes = block(first:last);
end

function [raw, byteOrder] = decodeRawThermalImage(bytes, cameraInfo)
    type = embeddedImageType(bytes);
    byteOrder = "native";
    switch type
        case "PNG"
            image = decodePng(bytes);
            [raw, byteOrder] = normalizeRawByteOrder(image);
        case "DAT"
            raw = decodeRawDat(bytes, cameraInfo);
        otherwise
            error('labkit:thermal:UnsupportedRawThermalImage', ...
                'Unsupported FLIR RawThermalImage payload type: %s', type);
    end
end

function [raw, byteOrder] = normalizeRawByteOrder(image)
    byteOrder = "native";
    if isa(image, 'uint16')
        native = double(image);
        swapped = double(swapbytes(image));
        if shouldUseSwappedRaw(native, swapped)
            raw = swapped;
            byteOrder = "swapped";
        else
            raw = native;
        end
    else
        raw = double(image);
    end
end

function tf = shouldUseSwappedRaw(native, swapped)
    nativeMax = max(native, [], 'all');
    nativeRange = nativeMax - min(native, [], 'all');
    swappedMax = max(swapped, [], 'all');
    swappedMedian = median(swapped(:), 'omitnan');
    tf = nativeMax > 60000 && nativeRange > 50000 && ...
        swappedMax < 50000 && swappedMedian > 1000;
end

function image = decodePng(bytes)
    signature = uint8([137 80 78 71 13 10 26 10]);
    starts = strfind(bytes, signature);
    if isempty(starts)
        error('labkit:thermal:UnsupportedRawThermalImage', ...
            'FLIR RawThermalImage record did not contain a PNG payload.');
    end
    bytes = bytes(starts(1):end);
    filepath = [tempname '.png'];
    fid = fopen(filepath, 'w');
    if fid < 0
        error('labkit:thermal:TempFileFailed', ...
            'Could not create a temporary PNG file for thermal image decoding.');
    end
    cleaner = onCleanup(@() cleanupTempFile(filepath));
    fwrite(fid, bytes, 'uint8');
    fclose(fid);
    warningState = warning('off', 'MATLAB:imagesci:png:tooManyIDATsData');
    warningCleaner = onCleanup(@() warning(warningState));
    image = imread(filepath);
end

function cleanupTempFile(filepath)
    if isfile(filepath)
        delete(filepath);
    end
end

function raw = decodeRawDat(bytes, cameraInfo)
    if ~isfield(cameraInfo, 'ImageWidth') || ~isfield(cameraInfo, 'ImageHeight')
        error('labkit:thermal:UnsupportedRawThermalImage', ...
            'Raw FLIR DAT payload requires CameraInfo image dimensions.');
    end
    width = double(cameraInfo.ImageWidth);
    height = double(cameraInfo.ImageHeight);
    payload = bytes;
    if numel(payload) >= 32
        payload = payload(33:end);
    end
    expectedBytes = width * height * 2;
    if numel(payload) < expectedBytes
        error('labkit:thermal:UnsupportedRawThermalImage', ...
            'Raw FLIR DAT payload is shorter than the declared image size.');
    end
    values = typecast(uint8(payload(1:expectedBytes)), 'uint16');
    raw = double(reshape(values, [width, height]).');
end

function type = embeddedImageType(bytes)
    pngSignature = uint8([137 80 78 71 13 10 26 10]);
    probeLength = min(numel(bytes), 64);
    probe = bytes(1:probeLength);
    if numel(bytes) >= 8 && (isequal(bytes(1:8), pngSignature) || ...
            ~isempty(strfind(probe, pngSignature)))
        type = "PNG";
    elseif numel(bytes) >= 3 && (isequal(bytes(1:3), uint8([255 216 255])) || ...
            ~isempty(strfind(probe, uint8([255 216 255]))))
        type = "JPG";
    else
        type = "DAT";
    end
end

function info = parseCameraInfo(bytes)
    info = struct();
    base = 1;
    if numel(bytes) >= 16 && readU16le(bytes, base) ~= 2 && ...
            readU16le(bytes, 9) == 2
        base = 9;
    end
    if numel(bytes) < base + hex2dec('30c') + 3
        return;
    end
    info.ImageWidth = readU16le(bytes, base + hex2dec('02'));
    info.ImageHeight = readU16le(bytes, base + hex2dec('04'));
    info.Emissivity = readF32le(bytes, base + hex2dec('20'));
    info.ObjectDistanceM = readF32le(bytes, base + hex2dec('24'));
    info.ReflectedApparentTemperatureC = kelvinToCelsius( ...
        readF32le(bytes, base + hex2dec('28')));
    info.AtmosphericTemperatureC = kelvinToCelsius( ...
        readF32le(bytes, base + hex2dec('2c')));
    info.IRWindowTemperatureC = kelvinToCelsius( ...
        readF32le(bytes, base + hex2dec('30')));
    info.IRWindowTransmission = readF32le(bytes, base + hex2dec('34'));
    humidity = readF32le(bytes, base + hex2dec('3c'));
    if humidity > 2
        humidity = humidity / 100;
    end
    info.RelativeHumidity = humidity;
    info.PlanckR1 = readF32le(bytes, base + hex2dec('58'));
    info.PlanckB = readF32le(bytes, base + hex2dec('5c'));
    info.PlanckF = readF32le(bytes, base + hex2dec('60'));
    info.AtmosphericTransAlpha1 = readF32le(bytes, base + hex2dec('70'));
    info.AtmosphericTransAlpha2 = readF32le(bytes, base + hex2dec('74'));
    info.AtmosphericTransBeta1 = readF32le(bytes, base + hex2dec('78'));
    info.AtmosphericTransBeta2 = readF32le(bytes, base + hex2dec('7c'));
    info.AtmosphericTransX = readF32le(bytes, base + hex2dec('80'));
    info.CameraTemperatureRangeMaxC = kelvinToCelsius( ...
        readF32le(bytes, base + hex2dec('90')));
    info.CameraTemperatureRangeMinC = kelvinToCelsius( ...
        readF32le(bytes, base + hex2dec('94')));
    info.CameraModel = readString(bytes, base + hex2dec('d4'), 32);
    info.CameraSoftware = readString(bytes, base + hex2dec('114'), 16);
    info.PlanckO = readI32le(bytes, base + hex2dec('308'));
    info.PlanckR2 = readF32le(bytes, base + hex2dec('30c'));
end

function [temperatureC, units, message, conversion] = ...
        convertTemperature(raw, cameraInfo, opts)
    units = "raw";
    message = "Raw thermal signal only; Planck calibration is incomplete.";
    temperatureC = NaN(size(raw));
    conversion = unavailableConversion(opts.TemperatureCorrection, message);
    if isempty(fieldnames(cameraInfo))
        return;
    end
    try
        [temperatureC, conversion] = labkit.thermal.rawToTemperatureC( ...
            raw, cameraInfo, ...
            struct('Correction', opts.TemperatureCorrection));
        units = "C";
        if conversion.usedDefaults
            message = "Temperature converted using embedded FLIR calibration; " + ...
                "warning: default correction parameters used for " + ...
                strjoin(conversion.defaultedFields, ", ") + ".";
        else
            message = "Temperature converted from FLIR raw signal using embedded calibration.";
        end
    catch ME
        if ~strcmp(ME.identifier, 'labkit:thermal:MissingCalibration')
            rethrow(ME);
        end
    end
end

function conversion = unavailableConversion(correction, message)
    conversion = struct( ...
        'available', false, ...
        'correction', string(correction), ...
        'usedDefaults', false, ...
        'defaultedFields', strings(0, 1), ...
        'parameterSources', struct(), ...
        'message', string(message));
end

function value = readU16be(bytes, startIndex)
    value = double(bytes(startIndex)) * 256 + double(bytes(startIndex + 1));
end

function value = readU32be(bytes, startIndex)
    value = double(bytes(startIndex)) * 16777216 + ...
        double(bytes(startIndex + 1)) * 65536 + ...
        double(bytes(startIndex + 2)) * 256 + ...
        double(bytes(startIndex + 3));
end

function value = readU16le(bytes, startIndex)
    value = double(typecast(uint8(bytes(startIndex:startIndex + 1)), 'uint16'));
end

function value = readI32le(bytes, startIndex)
    value = double(typecast(uint8(bytes(startIndex:startIndex + 3)), 'int32'));
end

function value = readF32le(bytes, startIndex)
    value = double(typecast(uint8(bytes(startIndex:startIndex + 3)), 'single'));
end

function text = readString(bytes, startIndex, count)
    last = min(numel(bytes), startIndex + count - 1);
    chunk = bytes(startIndex:last);
    zero = find(chunk == 0, 1);
    if ~isempty(zero)
        chunk = chunk(1:zero - 1);
    end
    text = string(char(chunk));
end

function value = kelvinToCelsius(value)
    if isfinite(value)
        % Constant: 273.15 is the exact Celsius-to-Kelvin zero-point offset.
        kelvinOffsetC = 273.15;
        value = value - kelvinOffsetC;
    end
end
