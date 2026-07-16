% Expected callers: RHS Preview actions. Inputs are the canonical collection,
% one app-owned role, and replacement records already carrying that role.
% Output removes the previous role records and appends replacements.
function sources = replaceSourceRecordsForRole(sources, role, replacements)
    if ~isempty(sources)
        sources(string({sources.role}) == string(role)) = [];
    end
    if isempty(replacements)
        return;
    end
    assert(all(string({replacements.role}) == string(role)), ...
        'rhs_preview:InvalidSourceRole', ...
        'Replacement source records must match role %s.', string(role));
    sources = [sources, replacements];
end
