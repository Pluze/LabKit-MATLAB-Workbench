% Expected caller: project_governance.run and tests. Input is app state.
% Output is status-panel text defining app scaffold fields and action results.
function lines = detailLines(S)
%DETAILLINES Return governance detail text.

    if nargin < 1 || ~isstruct(S)
        S = struct();
    end

    slug = fieldText(S, 'slug', 'new_app');
    command = "labkit_" + camelName(slug) + "_app";

    lines = { ...
        'New app fields'; ...
        ['Family folder: first folder under apps/, for example image_measurement, wearable, project, or templates.']; ...
        ['App slug: lower_snake_case folder and MATLAB package name, for example roughness or dta_cleaner.']; ...
        ['Public command: launch function name; blank means ' char(command) '.']; ...
        ['Window label: title text used by the generated app UI.']; ...
        ''; ...
        'Project code scan'; ...
        'Scan Project Code runs MATLAB Code Analyzer across repository .m files and writes matlab_code_check.json.'; ...
        ''; ...
        ['Last action: ' char(fieldText(S, 'lastAction', 'Ready'))]; ...
        ['Last result: ' char(fieldText(S, 'lastResult', 'Select Create app or Scan Project Code.'))]};
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
