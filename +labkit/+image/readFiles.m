function records = readFiles(paths, opts)
%READFILES Read image files into path/name/image records.
%
% Usage:
%   records = labkit.image.readFiles(paths)
%   records = labkit.image.readFiles(paths, opts)
%
% Description:
%   Reads one or more image files in the supplied order and returns a uniform
%   record for each file. The default path validates source extensions and
%   file existence, converts data with labkit.image.im2double, expands
%   grayscale to RGB, discards channels after the first three, and clamps
%   values to [0,1]. Set Normalize to false when the exact class and channel
%   layout returned by imread must be preserved.
%
%   progressFcn is called immediately before and after every imread. If a
%   read, conversion, or callback fails, the error propagates and no partial
%   records array is returned.
%
% Inputs:
%   paths - Character vector, string array, cell array, or empty value
%           accepted by labkit.image.normalizePaths.
%   opts - Optional scalar struct containing the fields listed below.
%
% Options:
%   Normalize - Logical scalar controlling conversion to clamped RGB double.
%               The default is true.
%   AllowEmpty - Logical scalar controlling whether an empty path collection
%                returns an empty record column. The default is true.
%   ValidateExtensions - Logical scalar controlling validation with
%                        assertSupportedPaths. The default is true.
%   RequireExisting - Logical scalar controlling the explicit file-existence
%                     check before imread. The default is true. imread can
%                     still fail when this option is false.
%   progressFcn - Function handle or []. The callback receives a scalar
%                 structure before and after each read. The default is [].
%
% Outputs:
%   records - N-by-1 structure array with path, name, and image fields. path
%             and name are strings; image contains the normalized or raw
%             image matrix.
%
% Progress Fields:
%   stage - "beforeRead" or "afterRead".
%   index - 1-based index of the current path.
%   count - Total number of paths.
%   path - Current path as a string scalar.
%   name - Filename and extension from labkit.image.displayName.
%
% Errors:
%   labkit:image:InvalidOptions - opts or one of its fields is invalid.
%   labkit:image:NoPaths - paths is empty while AllowEmpty is false.
%   labkit:image:UnsupportedImageFile - An extension is unsupported while
%                                       ValidateExtensions is true.
%   labkit:image:ImageFileNotFound - A file is missing while RequireExisting
%                                    is true.
%
% Typical Call:
%   opts = struct('Normalize', true, 'progressFcn', @updateProgress);
%   records = labkit.image.readFiles(selectedPaths, opts);
%
% See also labkit.image.normalizePaths,
%   labkit.image.assertSupportedPaths,
%   labkit.image.writeFile

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
            imageData = labkit.image.ensureRgb(labkit.image.im2double(imageData));
            imageData = min(max(imageData, 0), 1);
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
