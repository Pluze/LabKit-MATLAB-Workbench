% Private UI runtime helper. Expected callers: project restore and semantic
% state validation. Input is one durable project payload. Side effect: rejects
% noncanonical project buckets and malformed framework-owned source records
% before an App-specific validator runs.
function validateV2Project(project)
    if ~isstruct(project) || ~isscalar(project)
        invalid('Project must be a scalar struct.');
    end
    buckets = ["inputs", "parameters", "annotations", "results", "extensions"];
    missing = setdiff(buckets, string(fieldnames(project)));
    if ~isempty(missing)
        invalid('Project is missing required bucket(s): %s.', ...
            strjoin(cellstr(missing), ', '));
    end
    for k = 1:numel(buckets)
        field = char(buckets(k));
        if ~isstruct(project.(field)) || ~isscalar(project.(field))
            invalid('Project bucket "%s" must be a scalar struct.', field);
        end
    end
    if isfield(project.inputs, 'sources')
        validateSourceRecords(project.inputs.sources);
    end
end

function invalid(message, varargin)
    error('labkit:ui:runtime:InvalidState', message, varargin{:});
end
