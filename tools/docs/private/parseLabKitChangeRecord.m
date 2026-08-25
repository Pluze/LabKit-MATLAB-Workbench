function record = parseLabKitChangeRecord(text, source)
%PARSELABKITCHANGERECORD Parse one accepted Change page.

    text = string(text);
    source = string(source);
    lines = splitlines(text);
    blockName = "labkit-change";
    openLines = find(strip(lines) == "```" + blockName);
    if numel(openLines) ~= 1
        invalid(source, "must contain exactly one " + blockName + " block");
    end
    openLine = openLines(1);
    closeLine = find(strip(lines((openLine + 1):end)) == "```", 1) + openLine;
    if isempty(closeLine)
        invalid(source, "has an unterminated " + blockName + " block");
    end
    [fields, values] = metadata(lines((openLine + 1):(closeLine - 1)), source);

    record = emptyRecord();
    record.source = source;
    record.title = extractAfter(lines(1), "# ");
    requireScalars(fields, ["id", "date", "type", "compatibility"], source);
    allowOnly(fields, ["id", "date", "type", ...
        "compatibility", "component", "supersedes"], source);
    record.id = scalar(fields, values, "id");
    record.date = scalar(fields, values, "date");
    record.changeType = scalar(fields, values, "type");
    record.compatibility = scalar(fields, values, "compatibility");
    record.components = repeated(fields, values, "component");
    record.supersedes = repeated(fields, values, "supersedes");
    validateChange(record, source);
    headings = ["## Why", "## What changed", "## Impact", ...
        "## Compatibility and limits"];
    validateDate(record.date, source);
    headings = headings(:);
    requireBody(lines, closeLine, headings, source);
end

function [fields, values] = metadata(lines, source)
    if isempty(lines) || any(strlength(strip(lines)) == 0)
        invalid(source, "has an empty Change metadata line");
    end
    fields = strings(numel(lines), 1);
    values = strings(numel(lines), 1);
    for k = 1:numel(lines)
        token = regexp(char(lines(k)), '^([a-z][a-z-]*):\s+(.+)$', ...
            'tokens', 'once');
        if isempty(token)
            invalid(source, "has malformed Change metadata: " + lines(k));
        end
        fields(k) = string(token{1});
        values(k) = strip(string(token{2}));
    end
end

function requireScalars(fields, required, source)
    for field = required
        if sum(fields == field) ~= 1
            invalid(source, "must contain exactly one " + field + " field");
        end
    end
end

function allowOnly(fields, allowed, source)
    unknown = unique(fields(~ismember(fields, allowed)), "stable");
    if ~isempty(unknown)
        invalid(source, "uses unsupported field(s): " + strjoin(unknown, ", "));
    end
    repeatedScalars = allowed(arrayfun(@(field) ...
        sum(fields == field) > 1 && ~ismember(field, ...
        ["component", "supersedes"]), allowed));
    if ~isempty(repeatedScalars)
        invalid(source, "duplicates scalar field(s): " + ...
            strjoin(repeatedScalars, ", "));
    end
end

function value = scalar(fields, values, field)
    value = values(find(fields == field, 1));
end

function valuesOut = repeated(fields, values, field)
    valuesOut = values(fields == field);
end

function validateChange(record, source)
    if isempty(regexp(char(record.id), ...
            '^CHG-[0-9]{8}-[a-z0-9]+(?:-[a-z0-9]+)*$', 'once'))
        invalid(source, "has an invalid Change ID");
    end
    if ~ismember(record.changeType, ...
            ["feat", "fix", "perf", "refactor", "test", "docs", "ci", "chore"])
        invalid(source, "has an unsupported change type");
    end
    if ~ismember(record.compatibility, ...
            ["compatible", "action-required", "breaking"])
        invalid(source, "has unsupported compatibility");
    end
    requireComponents(record.components, source);
    expected = "changes/" + extractBetween(record.id, 5, 8) + "/" + record.id + ".md";
    if source ~= expected
        invalid(source, "must use the path " + expected);
    end
    requireIds(record.supersedes, '^CHG-[0-9]{8}-[a-z0-9]+(?:-[a-z0-9]+)*$', ...
        "superseded Change ID", source);
end

function requireComponents(values, source)
    if isempty(values)
        invalid(source, "must list at least one component");
    end
    expression = ['^[A-Za-z][A-Za-z0-9._-]*(?: \| ' ...
        '(?:new|[0-9]+\.[0-9]+\.[0-9]+) -> ' ...
        '[0-9]+\.[0-9]+\.[0-9]+)?$'];
    for value = values.'
        if isempty(regexp(char(value), expression, 'once'))
            invalid(source, "has an invalid component value: " + value);
        end
    end
end

function requireIds(values, expression, label, source)
    for value = values.'
        if isempty(regexp(char(value), expression, 'once'))
            invalid(source, "has an invalid " + label + ": " + value);
        end
    end
end

function validateDate(value, source)
    try
        parsed = datetime(value, "InputFormat", "yyyy-MM-dd", ...
            "Format", "yyyy-MM-dd");
    catch
        invalid(source, "has an invalid ISO date");
    end
    if string(parsed) ~= value
        invalid(source, "has an invalid ISO date");
    end
end

function requireBody(lines, metadataEnd, headings, source)
    headingLines = find(startsWith(lines, "## "));
    if numel(headingLines) ~= numel(headings) || ...
            ~isequal(lines(headingLines), headings) || ...
            headingLines(1) <= metadataEnd
        invalid(source, "does not use the canonical " + ...
            string(numel(headings)) + " body sections in order");
    end
    for k = 1:numel(headingLines)
        if k < numel(headingLines)
            section = lines((headingLines(k) + 1):(headingLines(k + 1) - 1));
        else
            section = lines((headingLines(k) + 1):end);
        end
        if ~any(strlength(strip(section)) > 0)
            invalid(source, "has an empty section: " + headings(k));
        end
    end
end

function record = emptyRecord()
    record = struct("source", "", "title", "", ...
        "id", "", "date", "", "changeType", "", ...
        "compatibility", "", "components", strings(0, 1), ...
        "supersedes", strings(0, 1));
end

function invalid(source, detail)
    error("LabKit:Docs:InvalidChange", ...
        "Change page %s %s.", source, detail);
end
