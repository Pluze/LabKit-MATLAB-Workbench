% Expected caller: project_governance.run and tests. Input is app state.
% Output is a two-column cell array previewing generated app files.
function rows = summaryRows(S)
%SUMMARYROWS Return generated-file preview rows.

    if nargin < 1 || ~isstruct(S)
        S = struct();
    end

    family = fieldText(S, 'family', 'templates');
    slug = fieldText(S, 'slug', 'new_app');
    entryPoint = fieldText(S, 'entryPoint', '');
    if strlength(entryPoint) == 0
        entryPoint = "labkit_" + camelName(slug) + "_app";
    end
    testName = camelName(slug) + "ScaffoldTest.m";
    appRoot = "apps/" + family + "/" + slug;

    rows = { ...
        'App folder', char(appRoot + "/"); ...
        'Public command file', char(appRoot + "/" + entryPoint + ".m"); ...
        'Package runner', char(appRoot + "/+" + slug + "/run.m"); ...
        'UI spec', char(appRoot + "/+" + slug + "/+ui/buildSpec.m"); ...
        'View helpers', char(appRoot + "/+" + slug + "/+view/"); ...
        'Unit test scaffold', char("tests/unit/apps/" + family + "/" + testName); ...
        'Code scan report', 'artifacts/code-check/matlab_code_check.json'};
end

function value = fieldText(S, fieldName, fallback)
    if isfield(S, fieldName) && strlength(string(S.(fieldName))) > 0
        value = string(S.(fieldName));
    else
        value = string(fallback);
    end
end

function name = camelName(slug)
    parts = split(string(slug), "_");
    for k = 1:numel(parts)
        parts(k) = upper(extractBefore(parts(k), 2)) + extractAfter(parts(k), 1);
    end
    name = strjoin(parts, "");
end
