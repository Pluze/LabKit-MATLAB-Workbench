function [records, report] = readFiles(paths, opts)
%READFILES Read several radiometric image files.
%
% Usage:
%   records = labkit.thermal.readFiles(paths)
%   records = labkit.thermal.readFiles(paths, opts)
%   [records, report] = labkit.thermal.readFiles(paths, opts)
%
% Description:
%   Calls labkit.thermal.readFile for each path in input order. By default, the
%   first unreadable file stops the operation. Set SkipInvalid to true when a
%   batch should keep its readable records and return a failure entry for each
%   skipped file.
%
% Inputs:
%   paths - Character vector, string array, or cell array of character vectors
%       and strings. Empty strings are removed. Output record order follows the
%       remaining input order.
%   opts - Optional scalar structure. See Options.
%
% Options:
%   AllowEmpty - Logical scalar. When true, an empty path list returns empty
%       records and a zero-count report. When false, an empty list throws
%       labkit:thermal:NoPaths. Default: true.
%   RequireExisting - Logical scalar forwarded to readFile. Default: true.
%   SkipInvalid - Logical scalar. When true, an unreadable file is added to
%       report.failures and processing continues. When false, its exception is
%       rethrown immediately. Default: false.
%   TemperatureCorrection - String scalar forwarded to readFile. Allowed
%       values are "environment" and "planck-basic". Default: "environment".
%   progressFcn - Empty or a function handle called once before each read and
%       again after it loads or is skipped. The callback receives a scalar
%       structure with stage, index, count, path, and name. stage is
%       "beforeRead", "afterRead", or "skipped". Default: [].
%
% Outputs:
%   records - Column structure array of successfully read thermal records. See
%       labkit.thermal.readFile for the fields in each element.
%   report - Scalar structure. requested is the number of normalized paths;
%       loaded and skipped are counts. failures is a structure array with path,
%       name, identifier, and message for each skipped file.
%
% Errors:
%   In addition to readFile errors, throws labkit:thermal:InvalidOptions when
%   opts or a callback is invalid and labkit:thermal:NoPaths when AllowEmpty is
%   false and no usable path remains.
%
% Typical Call:
%   opts = struct("SkipInvalid", true, ...
%       "TemperatureCorrection", "environment");
%   [records, report] = labkit.thermal.readFiles(files, opts);
%   fprintf("Loaded %d of %d files.\n", report.loaded, report.requested)

    if nargin < 2 || isempty(opts)
        opts = struct();
    end
    opts = normalizeOptions(opts);
    paths = normalizePaths(paths, opts.AllowEmpty);

    template = emptyRecord();
    records = repmat(template, 0, 1);
    failures = repmat(emptyFailure(), 0, 1);
    for k = 1:numel(paths)
        path = paths(k);
        reportProgress(opts.progressFcn, "beforeRead", k, numel(paths), path);
        readOpts = rmfield(opts, {'AllowEmpty', 'progressFcn', 'SkipInvalid'});
        try
            records(end + 1, 1) = labkit.thermal.readFile(path, readOpts);
            reportProgress(opts.progressFcn, "afterRead", k, numel(paths), path);
        catch ME
            if ~opts.SkipInvalid
                rethrow(ME);
            end
            failures(end + 1, 1) = failureFromException(path, ME);
            reportProgress(opts.progressFcn, "skipped", k, numel(paths), path);
        end
    end

    report = struct( ...
        'requested', numel(paths), ...
        'loaded', numel(records), ...
        'skipped', numel(failures), ...
        'failures', failures);
end

function opts = normalizeOptions(opts)
    if ~isstruct(opts) || ~isscalar(opts)
        error('labkit:thermal:InvalidOptions', ...
            'readFiles options must be a scalar struct.');
    end
    opts = struct( ...
        'AllowEmpty', optionValue(opts, 'AllowEmpty', true), ...
        'RequireExisting', optionValue(opts, 'RequireExisting', true), ...
        'SkipInvalid', optionValue(opts, 'SkipInvalid', false), ...
        'TemperatureCorrection', optionValue(opts, ...
        'TemperatureCorrection', "environment"), ...
        'progressFcn', optionValue(opts, 'progressFcn', []));
    logicalFields = ["AllowEmpty", "RequireExisting", "SkipInvalid"];
    for k = 1:numel(logicalFields)
        field = logicalFields(k);
        value = opts.(field);
        if ~((islogical(value) || isnumeric(value)) && isscalar(value))
            error('labkit:thermal:InvalidOptions', ...
                '%s must be a logical scalar.', field);
        end
        opts.(field) = logical(value);
    end
    if ~isempty(opts.progressFcn) && ~isa(opts.progressFcn, 'function_handle')
        error('labkit:thermal:InvalidOptions', ...
            'progressFcn must be a function handle when provided.');
    end
end

function paths = normalizePaths(paths, allowEmpty)
    if nargin < 2
        allowEmpty = true;
    end
    if isempty(paths)
        paths = strings(0, 1);
    elseif iscell(paths)
        paths = string(paths(:));
    else
        paths = string(paths);
        paths = paths(:);
    end
    paths = strip(paths);
    paths = paths(strlength(paths) > 0);
    if isempty(paths) && ~allowEmpty
        error('labkit:thermal:NoPaths', ...
            'At least one thermal image path is required.');
    end
end

function record = emptyRecord()
    record = struct('path', "", 'name', "", 'format', "", ...
        'raw', [], 'temperatureC', [], 'units', "", ...
        'metadata', struct(), 'message', "");
end

function failure = emptyFailure()
    failure = struct( ...
        'path', "", ...
        'name', "", ...
        'identifier', "", ...
        'message', "");
end

function failure = failureFromException(path, exception)
    failure = emptyFailure();
    failure.path = string(path);
    failure.name = displayName(path);
    failure.identifier = string(exception.identifier);
    failure.message = string(exception.message);
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
        'name', displayName(path)));
end

function name = displayName(path)
    [~, base, ext] = fileparts(char(path));
    name = string([base ext]);
end
