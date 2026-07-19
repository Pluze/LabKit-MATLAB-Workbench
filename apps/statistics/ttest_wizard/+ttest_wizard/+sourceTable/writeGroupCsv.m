% App group-data writer; writes one rectangular CSV with one column per group.
function writeGroupCsv(filepath, groups)
%WRITEGROUPCSV Write ordered numeric groups as a human-readable CSV.
%
% Expected caller: T-Test Wizard data export. filepath is a scalar output path.
% groups is a struct vector with label and finite numeric values fields. Output
% columns are Row followed by one uniquely named column per group, with blanks
% padding shorter groups. The only side effect is writing filepath.

    filepath = string(filepath);
    assert(isscalar(filepath) && strlength(filepath) > 0, ...
        'ttest_wizard:InvalidOutputPath', ...
        'Group CSV output path must be nonempty scalar text.');
    assert(isstruct(groups) && ...
        all(isfield(groups, {'label', 'values'})), ...
        'ttest_wizard:InvalidGroupData', ...
        'Group export requires label and values fields.');
    groups = groups(:);
    assert(~isempty(groups) && any(arrayfun( ...
        @(group) ~isempty(group.values), groups)), ...
        'ttest_wizard:NoVectorData', ...
        'At least one group with values is required for data export.');

    labels = strings(1, numel(groups));
    for k = 1:numel(groups)
        groups(k).values = finiteVector(groups(k).values, k);
        labels(k) = uniqueLabel(cleanLabel(groups(k).label, ...
            "Group " + k), labels(1:max(0, k - 1)));
    end
    count = max(arrayfun(@(group) numel(group.values), groups));
    data = cell(count + 1, numel(groups) + 1);
    data(1, :) = [{'Row'}, cellstr(labels)];
    for row = 1:count
        data{row + 1, 1} = row;
        for groupIndex = 1:numel(groups)
            if row <= numel(groups(groupIndex).values)
                data{row + 1, groupIndex + 1} = ...
                    groups(groupIndex).values(row);
            end
        end
    end
    writecell(data, filepath);
end

function value = finiteVector(value, index)
    assert(isnumeric(value) && (isempty(value) || isvector(value)), ...
        'ttest_wizard:InvalidVector', ...
        'Group %d values must be numeric.', index);
    value = double(value(:));
    assert(all(isfinite(value)), 'ttest_wizard:InvalidVector', ...
        'Group %d contains a nonfinite value.', index);
end

function value = cleanLabel(value, fallback)
    value = strip(string(value));
    assert(isscalar(value), 'ttest_wizard:InvalidLabel', ...
        'Group labels must be scalar text.');
    value = replace(value, [string(newline), string(char(13))], " ");
    if strlength(value) == 0
        value = fallback;
    end
end

function label = uniqueLabel(label, prior)
    base = label;
    suffix = 2;
    while any(strcmpi(label, prior))
        label = base + " " + suffix;
        suffix = suffix + 1;
    end
end
