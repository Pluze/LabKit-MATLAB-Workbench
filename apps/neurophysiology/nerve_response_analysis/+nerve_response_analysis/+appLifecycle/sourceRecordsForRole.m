% Expected callers: Nerve Response Analysis lifecycle, actions, and presenter.
% Input is the canonical source collection and one app-owned role. Output
% preserves order and contains only matching records; side effects are none.
function selected = sourceRecordsForRole(sources, role)
    if isempty(sources)
        selected = sources;
        return;
    end
    selected = sources(string({sources.role}) == string(role));
end
