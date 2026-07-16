% Expected callers: Nerve Response Analysis actions. Inputs are the canonical
% collection, one app-owned role, and replacement records carrying that role.
% Output removes previous role records and appends replacements.
function sources = replaceSourceRecordsForRole(sources, role, replacements)
    if ~isempty(sources)
        sources(string({sources.role}) == string(role)) = [];
    end
    if isempty(replacements)
        return;
    end
    assert(all(string({replacements.role}) == string(role)), ...
        'nerve_response_analysis:InvalidSourceRole', ...
        'Replacement source records must match role %s.', string(role));
    sources = [sources, replacements];
end
