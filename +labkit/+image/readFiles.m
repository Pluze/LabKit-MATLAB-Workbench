function records = readFiles(paths, opts)
%READFILES Read image files into path/name/image records.
%
% App-facing contract:
%   records = labkit.image.readFiles(paths)
%   records = labkit.image.readFiles(paths, opts)
%
% Inputs:
%   paths - char, string, cell array, or empty value accepted by
%       labkit.image.normalizePaths.
%   opts - optional struct with fields:
%       Normalize - logical scalar, default true. When true, grayscale images
%           are expanded to RGB, alpha channels are dropped, and image data is
%           converted to double in [0, 1]. When false, image data is returned
%           as read by imread.
%       AllowEmpty - logical scalar, default true.
%       ValidateExtensions - logical scalar, default true.
%       RequireExisting - logical scalar, default true.
%       progressFcn - function handle called before and after each read with
%           fields stage, index, count, path, and name.
%
% Outputs:
%   records - struct column with path, name, and image fields. App workflows
%       may copy these fields into app-owned item structs.

    if nargin < 2 || isempty(opts)
        opts = struct();
    end
    opts = normalizeOptions(opts);
    paths = labkit.image.normalizePaths(paths, "AllowEmpty", opts.AllowEmpty);
    if opts.ValidateExtensions
        labkit.image.assertSupportedPaths(paths);
    end

    template = struct('path', "", 'name', "", 'image', []);
    records = repmat(template, numel(paths), 1);
    for k = 1:numel(paths)
        path = paths(k);
        if opts.RequireExisting && exist(char(path), 'file') ~= 2
            error('labkit:image:ImageFileNotFound', ...
                'Image file does not exist: %s', char(path));
        end
        reportProgress(opts.progressFcn, "beforeRead", k, numel(paths), path);
        imageData = imread(char(path));
        if opts.Normalize
            imageData = labkit.image.toRgbDouble(imageData);
        end
        records(k) = struct( ...
            'path', path, ...
            'name', labkit.image.displayName(path), ...
            'image', imageData);
        reportProgress(opts.progressFcn, "afterRead", k, numel(paths), path);
    end
end

function opts = normalizeOptions(opts)
    if ~isstruct(opts) || ~isscalar(opts)
        error('labkit:image:InvalidOptions', ...
            'readFiles options must be a scalar struct.');
    end
    opts = struct( ...
        'Normalize', optionValue(opts, 'Normalize', true), ...
        'AllowEmpty', optionValue(opts, 'AllowEmpty', true), ...
        'ValidateExtensions', optionValue(opts, 'ValidateExtensions', true), ...
        'RequireExisting', optionValue(opts, 'RequireExisting', true), ...
        'progressFcn', optionValue(opts, 'progressFcn', []));
    logicalFields = ["Normalize", "AllowEmpty", "ValidateExtensions", "RequireExisting"];
    for k = 1:numel(logicalFields)
        field = logicalFields(k);
        value = opts.(field);
        if ~((islogical(value) || isnumeric(value)) && isscalar(value))
            error('labkit:image:InvalidOptions', ...
                '%s must be a logical scalar.', field);
        end
        opts.(field) = logical(value);
    end
    if ~isempty(opts.progressFcn) && ~isa(opts.progressFcn, 'function_handle')
        error('labkit:image:InvalidOptions', ...
            'progressFcn must be a function handle when provided.');
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isfield(opts, name)
        value = opts.(name);
    end
end

function reportProgress(progressFcn, stage, index, count, path)
    if isempty(progressFcn)
        return;
    end
    progressFcn(struct( ...
        'stage', string(stage), ...
        'index', index, ...
        'count', count, ...
        'path', string(path), ...
        'name', labkit.image.displayName(path)));
end
