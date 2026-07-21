function record = parseLabKitHistoryRecord(text, source)
%PARSELABKITHISTORYRECORD Read and validate one canonical LabKit history record.
% Expected caller: loadLabKitDocumentation history discovery.
% Inputs are Markdown text and its source-relative path. Output is the parsed
% record metadata used for history navigation, component aggregation, and
% search. Errors identify a noncanonical authored history record.

    lines = splitlines(string(text));
    titleLines = find(startsWith(lines, "# "));
    if numel(titleLines) ~= 1 || titleLines ~= 1
        invalid(source, "must begin with exactly one level-one title");
    end
    openLines = find(lines == "```labkit-change");
    if numel(openLines) ~= 1 || openLines ~= 3
        invalid(source, "must place one labkit-change block immediately after the title");
    end
    openLine = openLines(1);
    closeLine = find((lines == "```") & ((1:numel(lines)).' > openLine), 1);
    if isempty(closeLine)
        invalid(source, "has an unterminated labkit-change block");
    end
    metadataLines = lines(openLine + 1:closeLine - 1);
    if isempty(metadataLines) || any(strlength(strip(metadataLines)) == 0)
        invalid(source, "has an empty metadata line");
    end

    fields = strings(numel(metadataLines), 1);
    values = strings(numel(metadataLines), 1);
    for k = 1:numel(metadataLines)
        token = regexp(char(metadataLines(k)), '^([a-z]+): (.+)$', ...
            "tokens", "once");
        if isempty(token)
            invalid(source, "has malformed metadata: " + metadataLines(k));
        end
        fields(k) = string(token{1});
        values(k) = string(token{2});
    end

    scalarFields = ["id"; "date"; "sequence"; "type"; "compatibility"];
    if numel(fields) < numel(scalarFields) || ...
            ~isequal(fields(1:numel(scalarFields)), scalarFields)
        invalid(source, "must begin metadata with id, date, sequence, type, and compatibility");
    end
    allowedFields = [scalarFields; "component"; "scope"];
    unknown = unique(fields(~ismember(fields, allowedFields)), "stable");
    if ~isempty(unknown)
        invalid(source, "uses unsupported metadata field(s): " + strjoin(unknown, ", "));
    end
    for k = 1:numel(scalarFields)
        if sum(fields == scalarFields(k)) ~= 1
            invalid(source, "must contain exactly one " + scalarFields(k) + " field");
        end
    end
    trailingFields = fields(numel(scalarFields) + 1:end);
    firstScope = find(trailingFields == "scope", 1);
    if isempty(firstScope)
        invalid(source, "must contain at least one scope field");
    end
    if any(trailingFields(1:firstScope - 1) ~= "component") || ...
            any(trailingFields(firstScope:end) ~= "scope")
        invalid(source, "must list component fields before scope fields");
    end

    record = struct( ...
        "title", extractAfter(lines(1), "# "), ...
        "id", values(1), ...
        "date", values(2), ...
        "sequence", sequenceValue(values(3), source), ...
        "type", values(4), ...
        "compatibility", values(5), ...
        "components", values(fields == "component"), ...
        "scopes", values(fields == "scope"));
    validateRecord(record, lines, closeLine, source);
end

function validateRecord(record, lines, metadataEnd, source)
    if isempty(regexp(record.id, '^LK-[0-9]{8}-[a-z0-9]+(?:-[a-z0-9]+)*$', "once"))
        invalid(source, "has an invalid Change ID");
    end
    try
        parsedDate = datetime(record.date, "InputFormat", "yyyy-MM-dd", ...
            "Format", "yyyy-MM-dd");
    catch
        invalid(source, "has an invalid ISO date");
    end
    if string(parsedDate) ~= record.date
        invalid(source, "has an invalid ISO date");
    end
    legalTypes = ["feat", "fix", "perf", "refactor", "test", "docs", "ci", "chore"];
    if ~ismember(record.type, legalTypes)
        invalid(source, "has unsupported type: " + record.type);
    end
    if ~ismember(record.compatibility, ["compatible", "breaking"])
        invalid(source, "has unsupported compatibility: " + record.compatibility);
    end
    for k = 1:numel(record.components)
        value = record.components(k);
        expression = ['^`([A-Za-z][A-Za-z0-9._-]*)`(?: \| ' ...
            '`(?:new|[0-9]+\.[0-9]+\.[0-9]+) -> ' ...
            '[0-9]+\.[0-9]+\.[0-9]+`)?$'];
        if isempty(regexp(value, expression, "once"))
            invalid(source, "has an invalid component value: " + value);
        end
    end
    for k = 1:numel(record.scopes)
        value = record.scopes(k);
        if value ~= strip(value) || strlength(value) == 0 || strlength(value) > 96
            invalid(source, "has an invalid scope value");
        end
    end
    headings = [ ...
        "## Context"; "## Decision and rationale"; "## Changes"; ...
        "## User and data impact"; "## Compatibility and migration"; ...
        "## Validation"; "## Evidence"; ...
        "## Known limitations and follow-up"];
    headingLines = find(startsWith(lines, "## "));
    if numel(headingLines) ~= numel(headings) || ...
            ~isequal(lines(headingLines), headings) || headingLines(1) <= metadataEnd
        invalid(source, "must contain the eight canonical body sections in order");
    end
    for k = 1:numel(headingLines)
        if k < numel(headingLines)
            sectionLines = lines(headingLines(k) + 1:headingLines(k + 1) - 1);
        else
            sectionLines = lines(headingLines(k) + 1:end);
        end
        if ~any(strlength(strip(sectionLines)) > 0)
            invalid(source, "has an empty section: " + headings(k));
        end
    end
end

function value = sequenceValue(text, source)
    if isempty(regexp(text, '^[1-9][0-9]*$', "once"))
        invalid(source, "sequence must be a positive integer");
    end
    value = str2double(text);
end

function invalid(source, detail)
    error("LabKit:Docs:InvalidHistory", ...
        "History page %s %s.", source, detail);
end
