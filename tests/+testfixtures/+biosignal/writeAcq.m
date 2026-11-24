function path = writeAcq(folder, raw)
% Build a synthetic padded ACQ 133 frame stream with known calibration.
    if nargin < 2
        raw = [-12; 8; 0];
    end
    path = fullfile(folder, "recording.ACQ");
    file = fopen(path, 'wb', 'ieee-be');
    assert(file >= 0);
    cleaner = onCleanup(@() fclose(file));
    channelLengths = [154 160 168];
    graphLength = 2414;
    paddingLength = 40;
    foreignLength = 8;
    typeLength = 4 * numel(channelLengths);
    headerLength = graphLength + paddingLength + sum(channelLengths) + foreignLength + typeLength;
    fwrite(file, zeros(headerLength, 1, 'uint8'), 'uint8');
    writeAt(2, 133, 'uint32');
    writeAt(6, graphLength, 'int32');
    writeAt(10, numel(channelLengths), 'int16');
    writeAt(16, 0.5, 'double');
    writeAt(2398, 1, 'int16');
    writeAt(graphLength, paddingLength, 'int32');

    labels = ["Wave", "Reference", "Derived"];
    units = ["mV", "V", ""];
    cursor = graphLength + paddingLength;
    for channel = 1:numel(channelLengths)
        writeAt(cursor, channelLengths(channel), 'int32');
        writeAt(cursor + 6, char(labels(channel)), 'uint8');
        writeAt(cursor + 68, char(units(channel)), 'uint8');
        writeAt(cursor + 88, numel(raw), 'int32');
        writeAt(cursor + 92, -0.125, 'double');
        writeAt(cursor + 100, 0.25, 'double');
        writeAt(cursor + 152, 1, 'int16');
        cursor = cursor + channelLengths(channel);
    end
    writeAt(cursor, foreignLength, 'int32');
    writeAt(cursor + foreignLength, [2 2 8 1 8 0], 'int16');

    for k = 1:numel(raw)
        fwrite(file, raw(k), 'int16');
        fwrite(file, [k/4 -k], 'double');
    end

    function writeAt(offset, values, precision)
        assert(fseek(file, offset, 'bof') == 0);
        fwrite(file, values, precision);
    end
end
