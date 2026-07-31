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
    numberOfSignalGroups = readScalar(fid, "int16");
    groupTemplate = struct("name", "", "prefix", "", "enabled", false, ...
        "numChannels", 0, "numAmplifierChannels", 0);
    signalGroups = repmat(groupTemplate, 1, numberOfSignalGroups);
    familyNames = ["amplifier", "boardAdc", "boardDac", ...
        "boardDigIn", "boardDigOut"];
    familyChunks = cell(numel(familyNames), numberOfSignalGroups);
    triggerChunks = cell(1, numberOfSignalGroups);
    for groupIndex = 1:numberOfSignalGroups
        groupName = readQString(fid);
        groupPrefix = readQString(fid);
        groupEnabled = readScalar(fid, "int16") ~= 0;
        groupNumChannels = readScalar(fid, "int16");
        groupNumAmplifierChannels = readScalar(fid, "int16");
        signalGroups(groupIndex) = struct( ...
            "name", string(groupName), ...
            "prefix", string(groupPrefix), ...
            "enabled", groupEnabled, ...
            "numChannels", double(groupNumChannels), ...
            "numAmplifierChannels", double(groupNumAmplifierChannels));

        groupChannels = cell(numel(familyNames), groupNumChannels);
        groupCounts = zeros(1, numel(familyNames));
        groupTriggers = cell(1, groupNumChannels);
        triggerCount = 0;
        for channelIndex = 1:groupNumChannels
            [channel, trigger, signalType, channelEnabled] = readChannel(fid, ...
                groupName, groupPrefix, groupIndex);
            if ~(groupEnabled && channelEnabled)
                continue;
            end
            familyIndex = 0;
            switch signalType
                case 0
                    familyIndex = 1;
                    triggerCount = triggerCount + 1;
                    groupTriggers{triggerCount} = trigger;
                case 3
                    familyIndex = 2;
                case 4
                    familyIndex = 3;
                case 5
                    familyIndex = 4;
                case 6
                    familyIndex = 5;
                otherwise
                    % RHS files may include unused channel types inherited
                    % from the Intan header schema; only stored families are
                    % exposed by the RHS facade.
            end
            if familyIndex > 0
                groupCounts(familyIndex) = groupCounts(familyIndex) + 1;
                groupChannels{familyIndex, groupCounts(familyIndex)} = channel;
            end
        end
        for familyIndex = 1:numel(familyNames)
            if groupCounts(familyIndex) > 0
                familyChunks{familyIndex, groupIndex} = ...
                    [groupChannels{familyIndex, 1:groupCounts(familyIndex)}];
            end
        end
        if triggerCount > 0
            triggerChunks{groupIndex} = [groupTriggers{1:triggerCount}];
        end
    end
    for familyIndex = 1:numel(familyNames)
        chunks = familyChunks(familyIndex, :);
        chunks = chunks(~cellfun(@isempty, chunks));
        if ~isempty(chunks)
            families.(familyNames(familyIndex)) = [chunks{:}];
        end
    end
    triggerChunks = triggerChunks(~cellfun(@isempty, triggerChunks));
    if ~isempty(triggerChunks)
        spikeTriggers = [triggerChunks{:}];
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
    names = ["amplifier", "boardAdc", "boardDac", "boardDigIn", "boardDigOut"];
    channelCount = sum(arrayfun(@(name) numel(families.(name)), names));
    family = strings(channelCount, 1);
    nativeName = strings(channelCount, 1);
    customName = strings(channelCount, 1);
    nativeOrder = zeros(channelCount, 1);
    customOrder = zeros(channelCount, 1);
    chipChannel = zeros(channelCount, 1);
    boardStream = zeros(channelCount, 1);
    portName = strings(channelCount, 1);
    impedanceMagnitude = zeros(channelCount, 1);
    impedancePhase = zeros(channelCount, 1);
    row = 0;
    for iFamily = 1:numel(names)
        channels = families.(names(iFamily));
        for k = 1:numel(channels)
            row = row + 1;
            family(row, 1) = names(iFamily);
            nativeName(row, 1) = channels(k).nativeName;
            customName(row, 1) = channels(k).customName;
            nativeOrder(row, 1) = channels(k).nativeOrder;
            customOrder(row, 1) = channels(k).customOrder;
            chipChannel(row, 1) = channels(k).chipChannel;
            boardStream(row, 1) = channels(k).boardStream;
            portName(row, 1) = channels(k).portName;
            impedanceMagnitude(row, 1) = channels(k).electrodeImpedanceMagnitude;
            impedancePhase(row, 1) = channels(k).electrodeImpedancePhase;
        end
    end

    T = table(family, nativeName, customName, nativeOrder, customOrder, ...
        chipChannel, boardStream, portName, impedanceMagnitude, impedancePhase);
end
