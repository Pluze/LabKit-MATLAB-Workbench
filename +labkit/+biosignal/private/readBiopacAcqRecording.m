function recording = readBiopacAcqRecording(filepath, ~)
% Revision 133 uses a length-prefixed header chain before the interleaved
% waveform. File offsets are zero-based and multibyte fields are big-endian.
    file = fopen(filepath, 'rb', 'ieee-be');
    if file < 0
        error('labkit:biosignal:UnreadableAcq', 'Unable to open BIOPAC ACQ.');
    end
    cleanup = onCleanup(@() fclose(file));
    if fseek(file, 0, 'eof') ~= 0
        error('labkit:biosignal:UnreadableAcq', 'Unable to determine BIOPAC ACQ file size.');
    end
    fileBytes = ftell(file);

    revision = readAt(2, 1, 'uint32');
    if revision ~= 133
        error('labkit:biosignal:UnsupportedAcqRevision', ...
            'BIOPAC ACQ requires big-endian revision 133.');
    end
    graphEnd = blockEnd(0, 2400, 6);
    channelCount = readAt(10, 1, 'int16');
    intervalSec = readAt(16, 1, 'double') / 1000;
    sampleRate = 1 / intervalSec;
    if channelCount < 1 || intervalSec <= 0 || ~isfinite(intervalSec) || ~isfinite(sampleRate)
        error('labkit:biosignal:InvalidAcqHeader', ...
            'Invalid BIOPAC ACQ channel count or sample interval.');
    end
    if readAt(972, 1, 'int32') ~= 0
        error('labkit:biosignal:UnsupportedAcqCompression', ...
            'Compressed BIOPAC ACQ recordings are unsupported.');
    end
    paddingCount = readAt(2398, 1, 'int16');
    if paddingCount < 0 || paddingCount > floor((fileBytes - graphEnd) / 40)
        error('labkit:biosignal:InvalidAcqHeader', 'Invalid BIOPAC ACQ padding count.');
    end

    cursor = graphEnd;
    for k = 1:paddingCount
        cursor = blockEnd(cursor, 40, 0);
    end
    if channelCount > floor((fileBytes - cursor) / 154)
        error('labkit:biosignal:TruncatedAcq', 'BIOPAC ACQ channel headers exceed the file size.');
    end
    channels = repmat(struct('label', "", 'unit', "", 'count', 0, ...
        'scale', 0, 'offset', 0, 'divider', 0), 1, channelCount);
    for k = 1:channelCount
        next = blockEnd(cursor, 154, 0);
        channels(k).label = readText(cursor + 6, 40);
        channels(k).unit = readText(cursor + 68, 20);
        channels(k).count = readAt(cursor + 88, 1, 'int32');
        channels(k).scale = readAt(cursor + 92, 1, 'double');
        channels(k).offset = readAt(cursor + 100, 1, 'double');
        channels(k).divider = readAt(cursor + 152, 1, 'int16');
        cursor = next;
    end

    sampleCount = channels(1).count;
    if any([channels.count] < 1) || ~isfinite((sampleCount - 1) * intervalSec)
        error('labkit:biosignal:InvalidAcqHeader', ...
            'BIOPAC ACQ requires a positive channel sample count and finite duration.');
    end
    if any([channels.count] ~= sampleCount) || any([channels.divider] ~= 1)
        error('labkit:biosignal:UnsupportedAcqSampling', ...
            'BIOPAC ACQ requires equal channel lengths and a sample divider of 1.');
    end

    typeOffset = blockEnd(cursor, 4, 0);
    types = reshape(readAt(typeOffset, 2 * channelCount, 'int16'), 2, []);
    widths = types(1, :);
    codes = types(2, :);
    integer = widths == 2 & codes == 2;
    floating = widths == 8 & ismember(codes, [0 1]);
    if ~all(integer | floating)
        error('labkit:biosignal:UnsupportedAcqDataType', ...
            'Unsupported BIOPAC ACQ channel sample type or width.');
    end
    if any(~isfinite([channels(integer).scale])) || any(~isfinite([channels(integer).offset]))
        error('labkit:biosignal:InvalidAcqHeader', 'Invalid BIOPAC ACQ integer calibration.');
    end

    dataOffset = typeOffset + 4 * channelCount;
    frameBytes = sum(widths);
    if sampleCount > floor((fileBytes - dataOffset) / frameBytes)
        error('labkit:biosignal:TruncatedAcq', 'BIOPAC ACQ waveform is truncated.');
    end
    channelOffsets = [0 cumsum(widths(1:end - 1))];
    timeSec = (0:sampleCount - 1).' * intervalSec;
    signals = cell(1, channelCount);
    for k = 1:channelCount
        precision = 'double';
        if integer(k)
            precision = 'int16';
        end
        values = readAt(dataOffset + channelOffsets(k), sampleCount, ...
            precision, frameBytes - widths(k));
        if integer(k)
            values = values .* channels(k).scale + channels(k).offset;
        end
        name = channels(k).label;
        if strlength(name) == 0
            name = "Channel " + string(k);
        end
        metadata = struct('sourceKind', "biopac_acq", 'sourceColumn', k, ...
            'sampleIntervalSeconds', intervalSec, 'startSample', 0);
        signals{k} = makeSignalStruct(name, "", timeSec, values, metadata);
        signals{k}.fs = sampleRate;
        signals{k}.unit = channels(k).unit;
    end
    recording = makeRecording(filepath, "biopac_acq", [signals{:}]);
    recording.metadata.revision = revision;

    function next = blockEnd(start, minimumBytes, lengthOffset)
        bytes = readAt(start + lengthOffset, 1, 'int32');
        if bytes < minimumBytes || bytes > fileBytes - start
            error('labkit:biosignal:InvalidAcqHeader', ...
                'Invalid BIOPAC ACQ header length at byte %d.', start);
        end
        next = start + bytes;
    end

    function value = readText(offset, count)
        bytes = readAt(offset, count, '*uint8');
        terminator = find(bytes == 0, 1);
        if ~isempty(terminator)
            bytes = bytes(1:terminator - 1);
        end
        value = strip(string(native2unicode(bytes(:).', 'UTF-8')));
    end

    function values = readAt(offset, count, precision, skip)
        if nargin < 4
            skip = 0;
        end
        if offset > fileBytes || fseek(file, offset, 'bof') ~= 0
            error('labkit:biosignal:TruncatedAcq', ...
                'Unable to read BIOPAC ACQ section at byte %d.', offset);
        end
        [values, countRead] = fread(file, count, precision, skip);
        if countRead ~= count
            error('labkit:biosignal:TruncatedAcq', ...
                'Incomplete BIOPAC ACQ section at byte %d.', offset);
        end
    end
end
