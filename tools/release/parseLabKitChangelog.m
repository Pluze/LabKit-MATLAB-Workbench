function records = parseLabKitChangelog(filepath)
%PARSELABKITCHANGELOG Parse and validate structured LabKit change records.
%
% Usage:
%   records = parseLabKitChangelog();
%   records = parseLabKitChangelog("CHANGELOG.md");
%
% Inputs:
%   filepath - optional changelog path. Defaults to the repository
%              CHANGELOG.md associated with this tool.
%
% Outputs:
%   records - struct array with title, id, date, type, compatibility,
%             components, scopes, sections, and sourceLine fields. Component
%             entries contain name, kind, fromVersion, and toVersion; scopes
%             name unversioned repository surfaces such as CI or documentation.
%
% The parser reads every entry under `## Structured Change Records`; the
% changelog intentionally has no parallel unstructured history section.

    if nargin < 1 || strlength(string(filepath)) == 0
        root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
        filepath = fullfile(root, "CHANGELOG.md");
    end
    lines = splitlines(string(fileread(filepath)));
    [firstLine, lastLine] = recordSectionBounds(lines);
    headingLines = find(startsWith(lines, "### ") & ...
        (1:numel(lines)).' >= firstLine & (1:numel(lines)).' <= lastLine);
    records = repmat(emptyRecord(), 1, 0);
    for k = 1:numel(headingLines)
        recordEnd = lastLine;
        if k < numel(headingLines)
            recordEnd = headingLines(k + 1) - 1;
        end
        records(end + 1) = parseRecord(lines, headingLines(k), recordEnd);
    end
    validateRecordSet(records);
end

function [firstLine, lastLine] = recordSectionBounds(lines)
    startLine = find(lines == "## Structured Change Records", 1);
    endLine = find(lines == "## Current Version Lookup", 1);
    if isempty(startLine) || isempty(endLine) || endLine <= startLine
        error('LabKit:Changelog:MissingRecordSection', ...
            'CHANGELOG.md must place Structured Change Records before Current Version Lookup.');
    end
    firstLine = startLine + 1;
    lastLine = endLine - 1;
end

function record = parseRecord(lines, headingLine, recordEnd)
    record = emptyRecord();
    record.title = extractAfter(lines(headingLine), "### ");
    record.sourceLine = headingLine;
    cursor = nextContentLine(lines, headingLine + 1, recordEnd);
    if cursor > recordEnd || lines(cursor) ~= "```labkit-change"
        invalidRecord(record, 'must start with a ```labkit-change metadata block');
    end
    cursor = cursor + 1;
    while cursor <= recordEnd && lines(cursor) ~= "```"
        line = strtrim(lines(cursor));
        if strlength(line) > 0
            [key, value] = metadataPair(line, record);
            switch key
                case "schema"
                    record.schema = uniqueScalar(record.schema, value, key, record);
                case "id"
                    record.id = uniqueScalar(record.id, value, key, record);
                case "date"
                    record.date = uniqueScalar(record.date, value, key, record);
                case "type"
                    record.type = uniqueScalar(record.type, value, key, record);
                case "compatibility"
                    record.compatibility = uniqueScalar( ...
                        record.compatibility, value, key, record);
                case "component"
                    record.components(end + 1) = componentTransition(value, record);
                case "introduced"
                    record.components(end + 1) = introducedComponent(value, record);
                case "scope"
                    record.scopes(end + 1) = value;
                otherwise
                    invalidRecord(record, 'contains unknown metadata key ' + key);
            end
        end
        cursor = cursor + 1;
    end
    if cursor > recordEnd
        invalidRecord(record, 'has an unterminated metadata block');
    end
    record.sections = parseSections(lines, cursor + 1, recordEnd, record);
    validateRecord(record);
end

function [key, value] = metadataPair(line, record)
    delimiter = strfind(line, ":");
    if isempty(delimiter)
        invalidRecord(record, 'contains metadata without a key delimiter');
    end
    key = strtrim(extractBefore(line, delimiter(1)));
    value = strtrim(extractAfter(line, delimiter(1)));
end

function value = uniqueScalar(existing, value, key, record)
    if strlength(existing) > 0
        invalidRecord(record, 'repeats metadata key ' + key);
    end
end

function component = componentTransition(value, record)
    tokens = regexp(value, ...
        '^`([^`]+)`\s*\|\s*`(\d+\.\d+\.\d+)\s*->\s*(\d+\.\d+\.\d+)`$', ...
        'tokens', 'once');
    if isempty(tokens)
        invalidRecord(record, ...
            'has an invalid component transition; expected `name` | `X.Y.Z -> X.Y.Z`');
    end
    component = struct( ...
        "name", string(tokens{1}), ...
        "kind", "transition", ...
        "fromVersion", string(tokens{2}), ...
        "toVersion", string(tokens{3}));
end

function component = introducedComponent(value, record)
    tokens = regexp(value, '^`([^`]+)`\s*\|\s*`(\d+\.\d+\.\d+)`$', ...
        'tokens', 'once');
    if isempty(tokens)
        invalidRecord(record, ...
            'has invalid introduced metadata; expected `name` | `X.Y.Z`');
    end
    component = struct( ...
        "name", string(tokens{1}), ...
        "kind", "introduced", ...
        "fromVersion", "", ...
        "toVersion", string(tokens{2}));
end

function sections = parseSections(lines, firstLine, lastLine, record)
    sectionNames = [ ...
        "Context", "Decision and rationale", "Changes", ...
        "User and data impact", "Compatibility and migration", ...
        "Validation", "Evidence", "Known limitations and follow-up"];
    fieldNames = [ ...
        "context", "decisionAndRationale", "changes", ...
        "userAndDataImpact", "compatibilityAndMigration", ...
        "validation", "evidence", "knownLimitationsAndFollowUp"];
    sections = cell2struct(cellstr(repmat("", size(fieldNames))), ...
        cellstr(fieldNames), 2);
    headings = find(startsWith(lines(firstLine:lastLine), "#### ")) + firstLine - 1;
    for k = 1:numel(headings)
        name = extractAfter(lines(headings(k)), "#### ");
        index = find(sectionNames == name, 1);
        if isempty(index)
            invalidRecord(record, 'contains unknown narrative section ' + name);
        end
        contentEnd = lastLine;
        if k < numel(headings)
            contentEnd = headings(k + 1) - 1;
        end
        content = strtrim(strjoin(lines(headings(k) + 1:contentEnd), newline));
        sections.(fieldNames(index)) = content;
    end
end

function validateRecord(record)
    if record.schema ~= "1"
        invalidRecord(record, 'uses an unsupported or missing schema version');
    end
    if isempty(regexp(record.id, '^LK-\d{8}-[a-z0-9-]+$', 'once'))
        invalidRecord(record, 'has an invalid or missing Change ID');
    end
    if isempty(regexp(record.date, '^\d{4}-\d{2}-\d{2}$', 'once'))
        invalidRecord(record, 'has an invalid or missing ISO date');
    end
    try
        datetime(record.date, 'InputFormat', 'yyyy-MM-dd');
    catch
        invalidRecord(record, 'has a calendar-invalid date');
    end
    legalTypes = ["feat", "fix", "perf", "refactor", "test", "ci", "docs", "chore"];
    if ~any(record.type == legalTypes)
        invalidRecord(record, 'has an invalid or missing change type');
    end
    if ~any(record.compatibility == ["compatible", "additive", "breaking"])
        invalidRecord(record, 'has an invalid or missing compatibility value');
    end
    if isempty(record.components) && isempty(record.scopes)
        invalidRecord(record, ...
            'must declare at least one component transition or repository scope');
    end
    fields = string(fieldnames(record.sections));
    for k = 1:numel(fields)
        if strlength(strtrim(record.sections.(fields(k)))) == 0
            invalidRecord(record, 'is missing narrative section ' + fields(k));
        end
    end
end

function validateRecordSet(records)
    if isempty(records)
        error('LabKit:Changelog:NoStructuredRecords', ...
            'CHANGELOG.md must contain at least one structured change record.');
    end
    ids = string({records.id});
    if numel(unique(ids)) ~= numel(ids)
        error('LabKit:Changelog:DuplicateId', ...
            'Structured changelog Change IDs must be unique.');
    end
    dates = datetime(string({records.date}), 'InputFormat', 'yyyy-MM-dd');
    if any(diff(dates) > days(0))
        error('LabKit:Changelog:DateOrder', ...
            'Structured changelog records must use reverse chronological date order.');
    end
    validateComponentHistories(records);
end

function validateComponentHistories(records)
    components = [records.components];
    if isempty(components)
        return;
    end
    names = unique(string({components.name}), "stable");
    for k = 1:numel(names)
        name = names(k);
        events = components(string({components.name}) == name);
        introductions = events(string({events.kind}) == "introduced");
        transitions = events(string({events.kind}) == "transition");
        if numel(introductions) ~= 1
            error('LabKit:Changelog:ComponentIntroduction', ...
                'Component %s must have exactly one introduced event.', name);
        end
        fromVersions = string({transitions.fromVersion});
        if numel(unique(fromVersions)) ~= numel(fromVersions)
            error('LabKit:Changelog:ComponentBranch', ...
                'Component %s has multiple transitions from the same version.', name);
        end

        current = introductions.toVersion;
        consumed = false(size(transitions));
        while true
            next = find(~consumed & fromVersions == current);
            if isempty(next)
                break;
            end
            consumed(next) = true;
            current = transitions(next).toVersion;
        end
        if any(~consumed)
            error('LabKit:Changelog:ComponentHistoryGap', ...
                'Component %s has a disconnected, cyclic, or out-of-sequence version transition.', ...
                name);
        end
    end
end

function line = nextContentLine(lines, line, lastLine)
    while line <= lastLine && strlength(strtrim(lines(line))) == 0
        line = line + 1;
    end
end

function record = emptyRecord()
    record = struct( ...
        "title", "", ...
        "schema", "", ...
        "id", "", ...
        "date", "", ...
        "type", "", ...
        "compatibility", "", ...
        "components", repmat(struct( ...
        "name", "", "kind", "", "fromVersion", "", ...
        "toVersion", ""), 1, 0), ...
        "scopes", strings(1, 0), ...
        "sections", struct(), ...
        "sourceLine", 0);
end

function invalidRecord(record, detail)
    error('LabKit:Changelog:InvalidRecord', ...
        'Structured change record "%s" at line %d %s.', ...
        record.title, record.sourceLine, detail);
end
