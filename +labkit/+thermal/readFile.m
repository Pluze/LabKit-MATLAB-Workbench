function record = readFile(path, opts)
%READFILE Read one thermal image file into raw and temperature matrices.
%
% App-facing contract:
%   record = labkit.thermal.readFile(path)
%   record = labkit.thermal.readFile(path, opts)
%
% Inputs:
%   path - scalar char/string path to a supported thermal file. Current
%       implementation supports FLIR radiometric JPEG/RJPEG files containing
%       an FFF RawThermalImage record.
%   opts - optional scalar struct with fields:
%       RequireExisting - logical scalar, default true.
%       TemperatureCorrection - "environment" or "planck-basic", default
%           "environment". Environment mode uses emissivity, distance,
%           atmospheric/window transmission, reflected temperature, and Planck
%           constants when present. Basic mode applies only the Planck
%           radiance-to-temperature transform.
%
% Outputs:
%   record - struct with path, name, format, raw, temperatureC, units,
%       metadata, and message fields. temperatureC is NaN when the file has raw
%       data but lacks enough calibration constants.

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
