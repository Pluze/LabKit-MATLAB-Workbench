function record = readFile(path, opts)
%READFILE Read radiometric image data and convert it to degrees Celsius.
%
% Usage:
%   record = labkit.thermal.readFile(path)
%   record = labkit.thermal.readFile(path, opts)
%
% Description:
%   Reads the embedded FLIR FFF RawThermalImage record from a radiometric JPEG
%   or RJPEG. The ordinary visible JPEG pixels are not used as temperature
%   values. Raw sensor counts are retained alongside the converted matrix and
%   the calibration metadata used for conversion.
%
% Inputs:
%   path - Character vector or string scalar naming one .jpg, .jpeg, or .rjpg
%       file. The file must contain FLIR radiometric data.
%   opts - Optional scalar structure. See Options.
%
% Options:
%   RequireExisting - Logical scalar. When true, report a missing file before
%       checking its extension. Default: true.
%   TemperatureCorrection - String scalar selecting the temperature model.
%       Allowed values are "environment" and "planck-basic". "environment"
%       accounts for emissivity, object distance, reflected temperature,
%       atmosphere, humidity, and an infrared window when the metadata is
%       available. "planck-basic" applies only the camera's Planck constants
%       to the raw counts. Default: "environment".
%
% Outputs:
%   record - Scalar structure with fields path, name, format, raw,
%       temperatureC, units, metadata, and message. raw is the decoded sensor
%       matrix. temperatureC is a same-size double matrix in degrees Celsius,
%       or NaN when the raw data cannot be converted. metadata includes the
%       parsed FLIR tags and temperatureConversion diagnostics, including any
%       environmental values that used documented defaults.
%
% Errors:
%   Throws labkit:thermal:InvalidPath for a nonscalar path,
%   labkit:thermal:FileNotFound for a missing file when RequireExisting is
%   true, labkit:thermal:UnsupportedFile for another extension or a JPEG with
%   no supported radiometric payload, and labkit:thermal:InvalidOptions for an
%   invalid option value.
%
% Typical Call:
%   opts = struct("TemperatureCorrection", "environment");
%   record = labkit.thermal.readFile("capture.rjpg", opts);
%   imagesc(record.temperatureC)
%   axis image
%   colorbar

    if nargin < 2 || isempty(opts)
        opts = struct();
    end
    opts = normalizeOptions(opts);
    path = string(path);
    if ~isscalar(path)
        error('labkit:thermal:InvalidPath', ...
            'readFile expects one thermal image path.');
    end
    if opts.RequireExisting && exist(char(path), 'file') ~= 2
        error('labkit:thermal:FileNotFound', ...
            'Thermal image file does not exist: %s', char(path));
    end
    if ~labkit.thermal.isSupportedPath(path)
        error('labkit:thermal:UnsupportedFile', ...
            'Unsupported thermal image file extension: %s', char(path));
    end

    [~, ~, ext] = fileparts(char(path));
    switch lower(string(ext))
        case {".jpg", ".jpeg", ".rjpg"}
            record = readFlirRadiometricJpeg(path, opts);
        otherwise
            error('labkit:thermal:UnsupportedFile', ...
                'Unsupported thermal image file extension: %s', char(path));
    end
end

function opts = normalizeOptions(opts)
    if ~isstruct(opts) || ~isscalar(opts)
        error('labkit:thermal:InvalidOptions', ...
            'readFile options must be a scalar struct.');
    end
    opts = struct( ...
        'RequireExisting', optionValue(opts, 'RequireExisting', true), ...
        'TemperatureCorrection', string(optionValue(opts, ...
        'TemperatureCorrection', "environment")));
    if ~((islogical(opts.RequireExisting) || isnumeric(opts.RequireExisting)) && ...
            isscalar(opts.RequireExisting))
        error('labkit:thermal:InvalidOptions', ...
            'RequireExisting must be a logical scalar.');
    end
    opts.RequireExisting = logical(opts.RequireExisting);
    if ~any(opts.TemperatureCorrection == ["environment", "planck-basic"])
        error('labkit:thermal:InvalidOptions', ...
            'TemperatureCorrection must be "environment" or "planck-basic".');
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isfield(opts, name)
        value = opts.(name);
    end
end
