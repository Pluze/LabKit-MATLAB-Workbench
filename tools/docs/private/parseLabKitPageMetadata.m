function metadata = parseLabKitPageMetadata(text, source)
%PARSELABKITPAGEMETADATA Parse one restricted labkit-page block.

    lines = splitlines(string(text));
    titleLine = find(startsWith(lines, "# "), 1);
    starts = titleLine + 1;
    while starts <= numel(lines) && strlength(strip(lines(starts))) == 0
        starts = starts + 1;
    end
    metadata = struct( ...
        "present", false, ...
        "id", "", ...
        "type", "", ...
        "audience", "", ...
        "authority", "current", ...
        "summary", "");
    if isempty(titleLine) || starts > numel(lines) || ...
            strip(lines(starts)) ~= "```labkit-page"
        return;
    end
    finish = find(strip(lines((starts + 1):end)) == "```", 1) + starts;
    if isempty(finish)
        error("LabKit:Docs:UnclosedPageMetadata", ...
            "Documentation page has an unclosed labkit-page block: %s", source);
    end

    metadata.present = true;
    seen = strings(max(0, finish - starts - 1), 1);
    seenCount = 0;
    for k = (starts + 1):(finish - 1)
        line = strip(lines(k));
        if strlength(line) == 0
            continue;
        end
        token = regexp(char(line), '^([a-z][a-z-]*):\s+(.+)$', ...
            'tokens', 'once');
        if isempty(token)
            error("LabKit:Docs:InvalidPageMetadata", ...
                "Page metadata must use 'key: value' lines: %s", source);
        end
        key = string(token{1});
        value = strip(string(token{2}));
        if any(seen(1:seenCount) == key)
            error("LabKit:Docs:DuplicatePageMetadataField", ...
                "Page metadata field %s is duplicated: %s", key, source);
        end
        switch key
            case "id"
                metadata.id = value;
            case "type"
                metadata.type = value;
            case "audience"
                metadata.audience = value;
            case "summary"
                metadata.summary = value;
            otherwise
                error("LabKit:Docs:UnknownPageMetadataField", ...
                    "Page metadata field %s is not supported: %s", key, source);
        end
        seenCount = seenCount + 1;
        seen(seenCount, 1) = key;
    end
    seen = seen(1:seenCount);

    required = ["id", "type", "audience", "summary"];
    for k = 1:numel(required)
        if ~any(seen == required(k))
            error("LabKit:Docs:MissingPageMetadataField", ...
                "Page metadata is missing %s: %s", required(k), source);
        end
    end
    if isempty(regexp(char(metadata.id), '^[a-z][a-z0-9-]*$', 'once'))
        error("LabKit:Docs:InvalidPageId", ...
            "Page metadata id must be lowercase hyphenated text: %s", source);
    end
    legalTypes = ["landing", "tutorial", "task", "concept", ...
        "reference", "troubleshooting"];
    if ~any(metadata.type == legalTypes)
        error("LabKit:Docs:InvalidPageType", ...
            "Page metadata type is not supported: %s", source);
    end
    legalAudiences = ["new-user", "app-user", "scientific-user", ...
        "app-developer", "maintainer"];
    if ~any(metadata.audience == legalAudiences)
        error("LabKit:Docs:InvalidPageAudience", ...
            "Page metadata audience is not supported: %s", source);
    end
end
