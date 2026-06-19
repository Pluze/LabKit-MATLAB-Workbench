function [info, status] = inspectFile(filepath)
%INSPECTFILE Read Intan RHS header metadata without loading waveform data.
%
% Inputs:
%   filepath - char/string path to one .rhs file.
%
% Outputs:
%   info - struct with file version, sample rate, channel metadata, data
%          layout, block counts, duration, and exact-block status.
%   status - struct with ok, message, and filepath. Missing, malformed, or
%            unsupported files return ok=false instead of throwing after
%            filepath input validation.

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
