% Expected caller: labkit.rhs.inspectFile. Input is one existing RHS file.
% Output is GUI-free Intan RHS header and data-layout metadata. This parser
% follows the Intan RHS MATLAB reader block order and scaling metadata while
% avoiding base-workspace side effects.
function info = readHeader(filepath)
    fileInfo = dir(filepath);
    filesize = fileInfo.bytes;

    fid = fopen(filepath, "r", "ieee-le");
    if fid < 0
        error("labkit:rhs:OpenFailed", "Could not open RHS file.");
    end
    cleaner = onCleanup(@() fclose(fid));

    magicNumber = readScalar(fid, "uint32");
    if magicNumber ~= hex2dec("d69127ac")
        error("labkit:rhs:UnrecognizedFile", ...
            "Unrecognized Intan RHS file magic number.");
    end

    mainVersion = readScalar(fid, "int16");
    secondaryVersion = readScalar(fid, "int16");
    samplesPerBlock = 128;

    sampleRate = readScalar(fid, "single");
    dspEnabled = readScalar(fid, "int16");
    actualDspCutoff = readScalar(fid, "single");
    actualLowerBandwidth = readScalar(fid, "single");
    actualLowerSettleBandwidth = readScalar(fid, "single");
    actualUpperBandwidth = readScalar(fid, "single");

    desiredDspCutoff = readScalar(fid, "single");
    desiredLowerBandwidth = readScalar(fid, "single");
    desiredLowerSettleBandwidth = readScalar(fid, "single");
    desiredUpperBandwidth = readScalar(fid, "single");

    notchFilterMode = readScalar(fid, "int16");
    notchFilterFrequency = 0;
    if notchFilterMode == 1
        notchFilterFrequency = 50;
    elseif notchFilterMode == 2
        notchFilterFrequency = 60;
    end

    desiredImpedanceTestFrequency = readScalar(fid, "single");
    actualImpedanceTestFrequency = readScalar(fid, "single");

    ampSettleMode = readScalar(fid, "int16");
    chargeRecoveryMode = readScalar(fid, "int16");

    stimStepSize = readScalar(fid, "single");
    chargeRecoveryCurrentLimit = readScalar(fid, "single");
    chargeRecoveryTargetVoltage = readScalar(fid, "single");

    notes = struct( ...
        "note1", readQString(fid), ...
        "note2", readQString(fid), ...
        "note3", readQString(fid));

    dcAmplifierSaved = readScalar(fid, "int16") ~= 0;
    boardMode = readScalar(fid, "int16");
    referenceChannel = readQString(fid);

    frequencyParameters = struct( ...
        "amplifierSampleRateHz", sampleRate, ...
        "boardAdcSampleRateHz", sampleRate, ...
        "boardDigitalInSampleRateHz", sampleRate, ...
        "desiredDspCutoffFrequencyHz", desiredDspCutoff, ...
        "actualDspCutoffFrequencyHz", actualDspCutoff, ...
        "dspEnabled", dspEnabled ~= 0, ...
        "desiredLowerBandwidthHz", desiredLowerBandwidth, ...
        "desiredLowerSettleBandwidthHz", desiredLowerSettleBandwidth, ...
        "actualLowerBandwidthHz", actualLowerBandwidth, ...
        "actualLowerSettleBandwidthHz", actualLowerSettleBandwidth, ...
        "desiredUpperBandwidthHz", desiredUpperBandwidth, ...
        "actualUpperBandwidthHz", actualUpperBandwidth, ...
        "notchFilterFrequencyHz", notchFilterFrequency, ...
        "desiredImpedanceTestFrequencyHz", desiredImpedanceTestFrequency, ...
        "actualImpedanceTestFrequencyHz", actualImpedanceTestFrequency);

    stimParameters = struct( ...
        "stimStepSize", stimStepSize, ...
        "chargeRecoveryCurrentLimit", chargeRecoveryCurrentLimit, ...
        "chargeRecoveryTargetVoltage", chargeRecoveryTargetVoltage, ...
        "ampSettleMode", ampSettleMode, ...
        "chargeRecoveryMode", chargeRecoveryMode);

    [families, spikeTriggers, signalGroups] = readSignalGroups(fid);
    headerBytes = ftell(fid);
    counts = channelCounts(families);
    bytesPerBlock = blockBytes(samplesPerBlock, counts, dcAmplifierSaved);
    dataBytes = filesize - headerBytes;
    if bytesPerBlock > 0
        blockCount = floor(dataBytes / bytesPerBlock);
        exactBlocks = mod(dataBytes, bytesPerBlock) == 0;
    else
        blockCount = 0;
        exactBlocks = dataBytes == 0;
    end
    sampleCount = blockCount * samplesPerBlock;
    durationSec = sampleCount / sampleRate;

    [~, name, ext] = fileparts(filepath);
    info = struct( ...
        "type", "rhsInfo", ...
        "version", 1, ...
        "filepath", filepath, ...
        "name", string([name ext]), ...
        "fileVersion", [double(mainVersion) double(secondaryVersion)], ...
        "sampleRateHz", double(sampleRate), ...
        "samplesPerBlock", samplesPerBlock, ...
        "frequencyParameters", frequencyParameters, ...
        "stimParameters", stimParameters, ...
        "notes", notes, ...
        "dcAmplifierSaved", dcAmplifierSaved, ...
        "boardMode", double(boardMode), ...
        "referenceChannel", string(referenceChannel), ...
        "channelFamilies", families, ...
        "channelTable", channelTable(families), ...
        "spikeTriggers", spikeTriggers, ...
        "signalGroups", signalGroups, ...
        "fileBytes", filesize, ...
        "dataOffsetBytes", headerBytes, ...
        "bytesPerBlock", bytesPerBlock, ...
        "dataBytes", dataBytes, ...
        "blockCount", blockCount, ...
        "sampleCount", sampleCount, ...
        "durationSec", durationSec, ...
        "exactBlocks", exactBlocks);
end

function value = readScalar(fid, precision)
    value = fread(fid, 1, precision);
    if isempty(value)
        error("labkit:rhs:ShortHeader", "Unexpected end of RHS header.");
    end
end

function [families, spikeTriggers, signalGroups] = readSignalGroups(fid)
    families = emptyFamilies();
    spikeTriggers = emptySpikeTrigger();
    signalGroups = struct( ...
        "name", {}, ...
        "prefix", {}, ...
        "enabled", {}, ...
        "numChannels", {}, ...
        "numAmplifierChannels", {});

    numberOfSignalGroups = readScalar(fid, "int16");
    for groupIndex = 1:numberOfSignalGroups
        groupName = readQString(fid);
        groupPrefix = readQString(fid);
        groupEnabled = readScalar(fid, "int16") ~= 0;
        groupNumChannels = readScalar(fid, "int16");
        groupNumAmplifierChannels = readScalar(fid, "int16");
        signalGroups(end+1) = struct( ...
            "name", string(groupName), ...
            "prefix", string(groupPrefix), ...
            "enabled", groupEnabled, ...
            "numChannels", double(groupNumChannels), ...
            "numAmplifierChannels", double(groupNumAmplifierChannels));

        for channelIndex = 1:groupNumChannels
            [channel, trigger, signalType, channelEnabled] = readChannel(fid, ...
                groupName, groupPrefix, groupIndex);
            if ~(groupEnabled && channelEnabled)
                continue;
            end
            switch signalType
                case 0
                    families.amplifier(end+1) = channel;
                    spikeTriggers(end+1) = trigger;
                case 3
                    families.boardAdc(end+1) = channel;
                case 4
                    families.boardDac(end+1) = channel;
                case 5
                    families.boardDigIn(end+1) = channel;
                case 6
                    families.boardDigOut(end+1) = channel;
                otherwise
                    % RHS files may include unused channel types inherited
                    % from the Intan header schema; only stored families are
                    % exposed by the RHS facade.
            end
        end
    end
end

function [channel, trigger, signalType, enabled] = readChannel(fid, ...
        groupName, groupPrefix, groupIndex)
    channel = scalarChannel();
    trigger = scalarSpikeTrigger();

    channel.nativeName = string(readQString(fid));
    channel.customName = string(readQString(fid));
    channel.nativeOrder = double(readScalar(fid, "int16"));
    channel.customOrder = double(readScalar(fid, "int16"));
    signalType = readScalar(fid, "int16");
    enabled = readScalar(fid, "int16") ~= 0;
    channel.chipChannel = double(readScalar(fid, "int16"));
    readScalar(fid, "int16"); % command_stream, unused by app-facing API.
    channel.boardStream = double(readScalar(fid, "int16"));

    trigger.voltageTriggerMode = double(readScalar(fid, "int16"));
    trigger.voltageThreshold = double(readScalar(fid, "int16"));
    trigger.digitalTriggerChannel = double(readScalar(fid, "int16"));
    trigger.digitalEdgePolarity = double(readScalar(fid, "int16"));

    channel.portName = string(groupName);
    channel.portPrefix = string(groupPrefix);
    channel.portNumber = double(groupIndex);
    channel.electrodeImpedanceMagnitude = double(readScalar(fid, "single"));
    channel.electrodeImpedancePhase = double(readScalar(fid, "single"));
end

function families = emptyFamilies()
    families = struct();
    families.amplifier = emptyChannel();
    families.boardAdc = emptyChannel();
    families.boardDac = emptyChannel();
    families.boardDigIn = emptyChannel();
    families.boardDigOut = emptyChannel();
end

function channel = emptyChannel()
    channel = struct( ...
        "nativeName", {}, ...
        "customName", {}, ...
        "nativeOrder", {}, ...
        "customOrder", {}, ...
        "boardStream", {}, ...
        "chipChannel", {}, ...
        "portName", {}, ...
        "portPrefix", {}, ...
        "portNumber", {}, ...
        "electrodeImpedanceMagnitude", {}, ...
        "electrodeImpedancePhase", {});
end

function trigger = emptySpikeTrigger()
    trigger = struct( ...
        "voltageTriggerMode", {}, ...
        "voltageThreshold", {}, ...
        "digitalTriggerChannel", {}, ...
        "digitalEdgePolarity", {});
end

function channel = scalarChannel()
    channel = struct( ...
        "nativeName", "", ...
        "customName", "", ...
        "nativeOrder", NaN, ...
        "customOrder", NaN, ...
        "boardStream", NaN, ...
        "chipChannel", NaN, ...
        "portName", "", ...
        "portPrefix", "", ...
        "portNumber", NaN, ...
        "electrodeImpedanceMagnitude", NaN, ...
        "electrodeImpedancePhase", NaN);
end

function trigger = scalarSpikeTrigger()
    trigger = struct( ...
        "voltageTriggerMode", NaN, ...
        "voltageThreshold", NaN, ...
        "digitalTriggerChannel", NaN, ...
        "digitalEdgePolarity", NaN);
end

function counts = channelCounts(families)
    counts = struct( ...
        "amplifier", numel(families.amplifier), ...
        "boardAdc", numel(families.boardAdc), ...
        "boardDac", numel(families.boardDac), ...
        "boardDigIn", numel(families.boardDigIn), ...
        "boardDigOut", numel(families.boardDigOut));
end

function nBytes = blockBytes(samplesPerBlock, counts, dcAmplifierSaved)
    nBytes = samplesPerBlock * 4;
    if dcAmplifierSaved
        nBytes = nBytes + samplesPerBlock * (2 + 2 + 2) * counts.amplifier;
    else
        nBytes = nBytes + samplesPerBlock * (2 + 2) * counts.amplifier;
    end
    nBytes = nBytes + samplesPerBlock * 2 * counts.boardAdc;
    nBytes = nBytes + samplesPerBlock * 2 * counts.boardDac;
    if counts.boardDigIn > 0
        nBytes = nBytes + samplesPerBlock * 2;
    end
    if counts.boardDigOut > 0
        nBytes = nBytes + samplesPerBlock * 2;
    end
end

function T = channelTable(families)
    family = strings(0, 1);
    nativeName = strings(0, 1);
    customName = strings(0, 1);
    nativeOrder = zeros(0, 1);
    customOrder = zeros(0, 1);
    chipChannel = zeros(0, 1);
    boardStream = zeros(0, 1);
    portName = strings(0, 1);
    impedanceMagnitude = zeros(0, 1);
    impedancePhase = zeros(0, 1);

    names = ["amplifier", "boardAdc", "boardDac", "boardDigIn", "boardDigOut"];
    for iFamily = 1:numel(names)
        channels = families.(names(iFamily));
        for k = 1:numel(channels)
            family(end+1, 1) = names(iFamily);
            nativeName(end+1, 1) = channels(k).nativeName;
            customName(end+1, 1) = channels(k).customName;
            nativeOrder(end+1, 1) = channels(k).nativeOrder;
            customOrder(end+1, 1) = channels(k).customOrder;
            chipChannel(end+1, 1) = channels(k).chipChannel;
            boardStream(end+1, 1) = channels(k).boardStream;
            portName(end+1, 1) = channels(k).portName;
            impedanceMagnitude(end+1, 1) = channels(k).electrodeImpedanceMagnitude;
            impedancePhase(end+1, 1) = channels(k).electrodeImpedancePhase;
        end
    end

    T = table(family, nativeName, customName, nativeOrder, customOrder, ...
        chipChannel, boardStream, portName, impedanceMagnitude, impedancePhase);
end
