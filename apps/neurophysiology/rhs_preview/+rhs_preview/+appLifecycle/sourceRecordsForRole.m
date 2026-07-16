% Expected callers: RHS Preview lifecycle, actions, and presenter. Input is the
% canonical project source collection and one app-owned role. Output preserves
% source order and contains only records with that role; side effects are none.
function selected = sourceRecordsForRole(sources, role)
    if isempty(sources)
        selected = sources;
        return;
    end
    selected = sources(string({sources.role}) == string(role));
end
