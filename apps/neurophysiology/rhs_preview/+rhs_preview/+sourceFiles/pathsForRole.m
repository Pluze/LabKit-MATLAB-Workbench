% Return resolved source paths for one RHS Preview source role. The App owns
% role selection and ordering; Runtime V2 owns portable-reference decoding.
function paths = pathsForRole(sources, role)
    if isempty(sources)
        paths = strings(0, 1);
        return;
    end
    role = string(role);
    assert(isscalar(role) && strlength(role) > 0, ...
        'rhs_preview:InvalidSourceRole', ...
        'RHS Preview source role must be nonempty scalar text.');
    selected = string({sources.role}) == role;
    ids = string({sources(selected).id});
    paths = labkit.ui.runtime.sourcePaths(sources, ids);
end
