function info = inspectFile(path, opts)
%INSPECTFILE Report whether one file contains readable thermal data.
%
% App-facing contract:
%   info = labkit.thermal.inspectFile(path)
%   info = labkit.thermal.inspectFile(path, opts)
%
% Inputs:
%   path - scalar char/string path.
%   opts - optional scalar struct with fields accepted by
%       labkit.thermal.readFile.
%
% Outputs:
%   info - scalar struct with path, name, supportedExtension, isThermal,
%       format, identifier, and message fields. This function catches reader
%       failures and never throws for unsupported or non-radiometric image
%       content.

    if nargin < 2 || isempty(opts)
        opts = struct();
    end
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
