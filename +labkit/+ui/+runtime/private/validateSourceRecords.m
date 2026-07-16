% Private Runtime V2 source contract validator. Expected callers are state
% validation and injected project services. Input is an empty value or source
% struct array. Side effect: rejects missing, empty, nonscalar, or duplicate
% durable source ids before lookup, persistence, or presentation.
function validateSourceRecords(sources)
    if isempty(sources)
        return;
    end
    if ~isstruct(sources) || ~isfield(sources, 'id')
        invalid('Project sources must be a struct array with id fields.');
    end
    ids = strings(numel(sources), 1);
    for k = 1:numel(sources)
        value = sources(k).id;
        if ~(ischar(value) || (isstring(value) && isscalar(value))) || ...
                strlength(string(value)) == 0
            invalid('Project source %d id must be nonempty scalar text.', k);
        end
        ids(k) = string(value);
    end
    [uniqueIds, first] = unique(ids, 'stable');
    if numel(uniqueIds) ~= numel(ids)
        repeated = ids(setdiff(1:numel(ids), first, 'stable'));
        invalid('Project source ids must be unique; duplicate "%s".', ...
            repeated(1));
    end
end

function invalid(message, varargin)
    error('labkit:ui:runtime:InvalidSourceRecords', message, varargin{:});
end
