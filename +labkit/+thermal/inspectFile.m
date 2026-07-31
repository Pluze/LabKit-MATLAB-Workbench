function info = inspectFile(path, opts)
%INSPECTFILE Check whether a file contains supported radiometric data.
%
% Usage:
%   info = labkit.thermal.inspectFile(path)
%   info = labkit.thermal.inspectFile(path, opts)
%
% Description:
%   Performs the same format check and radiometric read as readFile, but
%   returns the outcome instead of throwing when the extension, file contents,
%   or calibration data are unsupported. Use this function to label files in a
%   chooser or batch review before deciding which ones to read.
%
% Inputs:
%   path - Character vector or string scalar naming one candidate file.
%   opts - Optional scalar structure. See Options.
%
% Options:
%   RequireExisting - Logical scalar forwarded to readFile. Default: true.
%   TemperatureCorrection - "environment" or "planck-basic", forwarded to
%       readFile. Default: "environment".
%
% Outputs:
%   info - Scalar structure with path, name, supportedExtension, isThermal,
%       format, identifier, and message. supportedExtension reports only the
%       filename extension. isThermal is true only after a supported
%       radiometric payload is read successfully. On failure, identifier and
%       message contain the caught reader error.
%
% Failure Behavior:
%   Unsupported extensions and all readFile failures return isThermal=false
%   with identifier and message populated; those reader exceptions are not
%   rethrown. path must still be convertible to scalar text, and malformed
%   MATLAB values may raise the originating conversion error.
%   Unknown option fields or a non-struct opts value throw
%   labkit:thermal:InvalidOptions.
%
% Example:
%   info = labkit.thermal.inspectFile("candidate.jpg");
%   if info.isThermal
%       fprintf("Readable thermal format: %s\n", info.format)
%   else
%       warning("%s", info.message)
%   end
%
% See also labkit.thermal.readFile,
%   labkit.thermal.isSupportedPath

    if nargin < 2
        opts = struct();
    end
    validateOptionStruct(opts, ["RequireExisting", "TemperatureCorrection"]);
    [~, base, ext] = fileparts(char(string(path)));
    info = struct( ...
        'path', string(path), ...
        'name', string([base ext]), ...
        'supportedExtension', labkit.thermal.isSupportedPath(path), ...
        'isThermal', false, ...
        'format', "", ...
        'identifier', "", ...
        'message', "");

    if ~info.supportedExtension
        info.identifier = "labkit:thermal:UnsupportedFile";
        info.message = "Unsupported thermal image file extension.";
        return;
    end

    try
        record = labkit.thermal.readFile(path, opts);
        info.isThermal = true;
        info.format = record.format;
        info.message = record.message;
    catch ME
        info.identifier = string(ME.identifier);
        info.message = string(ME.message);
    end
end
