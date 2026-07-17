function paths = sourcePaths(sources, ids)
%SOURCEPATHS Read resolved paths from Runtime V2 source records.
%
% Usage:
%   paths = labkit.ui.runtime.sourcePaths(sources)
%   paths = labkit.ui.runtime.sourcePaths(sources, ids)
%
% Inputs:
%   sources - Runtime V2 source struct array. Apps normally initialize an
%       empty collection with labkit.ui.runtime.emptySourceRecords and add
%       records through services.project.sourceRecord, upsertSource, or
%       reconcileSources.
%   ids - Optional source ID or collection of source IDs. Requested IDs are
%       returned in the supplied order. An ID that has not been added yet
%       returns an empty string in that position. When omitted, paths follow
%       source-record order.
%
% Outputs:
%   paths - Column string array containing each source's current resolved
%       path. An empty source collection or empty ids input returns a 0-by-1
%       string array.
%
% Description:
%   Source IDs, roles, and required flags are App-facing project data. The
%   nested portable-reference representation is owned by Runtime V2 and may
%   evolve independently. Use sourcePaths wherever App code needs to read a
%   file, compare selected files, build a session cache, or present a path.
%
% Errors:
%   labkit:ui:runtime:InvalidSourceRecords - A source record, requested ID,
%       or runtime-owned reference is malformed.
%
% Example:
%   sources = labkit.ui.runtime.emptySourceRecords();
%   assert(isempty(labkit.ui.runtime.sourcePaths(sources)))
%
% See also labkit.ui.runtime.emptySourceRecords,
%   labkit.ui.runtime.defaultOutputFolder

    if nargin < 1
        error('labkit:ui:runtime:InvalidSourceRecords', ...
            'Source records are required.');
    end
    validateSourceRecords(sources);

    sourceIds = strings(0, 1);
    if ~isempty(sources)
        sourceIds = string({sources.id}).';
    end
    indices = (1:numel(sources)).';
    if nargin >= 2
        requested = normalizeIds(ids);
        if isempty(requested)
            paths = strings(0, 1);
            return;
        end
        [~, indices] = ismember(requested, sourceIds);
    end

    paths = strings(numel(indices), 1);
    for k = 1:numel(indices)
        if indices(k) == 0
            continue;
        end
        source = sources(indices(k));
        if ~isfield(source, 'reference') || ...
                ~isstruct(source.reference) || ...
                ~isscalar(source.reference) || ...
                ~isfield(source.reference, 'originalPath')
            invalidReference(sourceIds(indices(k)));
        end
        value = source.reference.originalPath;
        if ~(ischar(value) || (isstring(value) && isscalar(value)))
            invalidReference(sourceIds(indices(k)));
        end
        paths(k) = string(value);
    end
end

function ids = normalizeIds(value)
    if ~(ischar(value) || isstring(value) || iscellstr(value))
        error('labkit:ui:runtime:InvalidSourceRecords', ...
            'Requested source ids must be text.');
    end
    ids = string(value);
    ids = ids(:);
    if any(strlength(ids) == 0)
        error('labkit:ui:runtime:InvalidSourceRecords', ...
            'Requested source ids must be nonempty text.');
    end
end

function invalidReference(id)
    error('labkit:ui:runtime:InvalidSourceRecords', ...
        'Project source "%s" has no valid resolved path reference.', id);
end
