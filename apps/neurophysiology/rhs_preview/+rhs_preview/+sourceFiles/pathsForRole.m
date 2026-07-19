% Return resolved source paths for one RHS Preview source role. The App owns
% role selection and ordering; Runtime V2 owns portable-reference decoding.
function paths = pathsForRole(sources, role, callbackContext)
    if isempty(sources)
        paths = strings(0, 1);
        return;
    end
    role = string(role);
    assert(isscalar(role) && strlength(role) > 0, ...
        'rhs_preview:InvalidSourceRole', ...
        'RHS Preview source role must be nonempty scalar text.');
    selected = string({sources.role}) == role;
    selectedSources = sources(selected);
    if nargin >= 3
        paths = callbackContext.resolveSourcePaths(selectedSources);
        return;
    end
    paths = strings(numel(selectedSources), 1);
    for k = 1:numel(selectedSources)
        if isfield(selectedSources, "reference")
            paths(k) = string( ...
                selectedSources(k).reference.originalPath);
        elseif isfield(selectedSources, "path")
            paths(k) = string(selectedSources(k).path);
        end
    end
end
