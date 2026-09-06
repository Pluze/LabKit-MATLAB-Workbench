function [info, status] = inspectFile(filepath)
%INSPECTFILE Read metadata and data-layout information from an RHS file.
%
% Usage:
%   [info, status] = labkit.rhs.inspectFile(filepath)
%
% Description:
%   Reads the Intan RHS header and calculates the complete-block count,
%   available sample count, and recording duration without loading waveform
%   arrays. A missing, malformed, or unsupported file is returned as
%   status.ok=false after filepath validation.
%
% Inputs:
%   filepath - Character vector or string scalar naming one RHS file.
%
% Outputs:
%   info - Scalar structure containing the parsed header and calculated file
%       layout. On failure, identity fields remain available and other fields
%       contain empty or NaN values.
%   status - Scalar structure with ok, message, and filepath. message is empty
%       on success and explains the read failure otherwise.
%
% Output Fields:
%   fileVersion - Two-element numeric vector [major minor].
%   sampleRateHz - Amplifier sample rate in hertz.
%   durationSec - Duration represented by complete data blocks, in seconds.
%   channelFamilies - Structures for amplifier, boardAdc, boardDac,
%       boardDigIn, and boardDigOut channels.
%   channelTable - Table containing family and channel-name metadata for all
%       enabled stored channels.
%   frequencyParameters - Requested and actual filter/sample frequencies.
%   stimParameters - Stimulation step size and charge-recovery settings.
%   dcAmplifierSaved - Logical flag indicating whether DC amplifier samples
%       are present.
%   dataOffsetBytes - Byte offset of the first waveform block.
%   bytesPerBlock - Calculated bytes in one complete 128-sample block.
%   blockCount - Number of complete waveform blocks.
%   sampleCount - Number of samples in complete blocks.
%   exactBlocks - True when the data section has no trailing partial bytes.
%
% Errors:
%   Throws labkit:rhs:InvalidFilepath when filepath is not a character vector
%   or string scalar. File-open and header-format errors are returned in
%   status instead of thrown.
%
% Typical Call:
%   [info, status] = labkit.rhs.inspectFile("recording.rhs");
%   if status.ok
%       fprintf("%.1f s at %.0f Hz\n", info.durationSec, info.sampleRateHz)
%       disp(info.channelTable(:, ["family", "nativeName", "customName"]))
%   end
%
% See also labkit.rhs.indexFile,
%   labkit.rhs.readWindow,
%   labkit.rhs.findFiles

    filepath = normalizeFilepath(filepath);
    info = emptyInfo(filepath);
    status = makeStatus(filepath, false, "");

    if exist(filepath, "file") ~= 2
        status.message = "File not found.";
        return;
    end

    try
        info = readHeader(filepath);
        status = makeStatus(filepath, true, "");
    catch ME
        status = makeStatus(filepath, false, string(ME.message));
    end
end

function info = emptyInfo(filepath)
    [~, name, ext] = fileparts(filepath);
    info = struct( ...
        "type", "rhsInfo", ...
        "version", 1, ...
        "filepath", filepath, ...
        "name", string([name ext]), ...
        "fileVersion", [NaN NaN], ...
        "sampleRateHz", NaN, ...
        "durationSec", NaN, ...
        "channelFamilies", struct(), ...
        "channelTable", table(), ...
        "dataOffsetBytes", NaN, ...
        "bytesPerBlock", NaN, ...
        "blockCount", 0, ...
        "sampleCount", 0, ...
        "exactBlocks", false);
end
