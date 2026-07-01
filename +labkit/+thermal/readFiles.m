function [records, report] = readFiles(paths, opts)
%READFILES Read thermal image files into raw and temperature records.
%
% App-facing contract:
%   records = labkit.thermal.readFiles(paths)
%   records = labkit.thermal.readFiles(paths, opts)
%   [records, report] = labkit.thermal.readFiles(paths, opts)
%
% Inputs:
%   paths - char, string, cell array, or empty value accepted by local path
%       normalization.
%   opts - optional scalar struct with fields:
%       AllowEmpty - logical scalar, default true.
%       RequireExisting - logical scalar, default true.
%       SkipInvalid - logical scalar, default false. When true, files that do
%           not contain readable thermal payloads are skipped and reported
%           instead of aborting the whole read.
%       TemperatureCorrection - forwarded to labkit.thermal.readFile.
%       progressFcn - function handle called before and after each read with
%           fields stage, index, count, path, and name.
%
% Outputs:
%   records - struct column returned by repeated labkit.thermal.readFile
%       calls. App workflows may copy these records into app-owned item
%       structs.
%   report - struct with requested, loaded, skipped, and failures fields.

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
