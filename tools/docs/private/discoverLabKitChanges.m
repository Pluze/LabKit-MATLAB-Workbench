function changes = discoverLabKitChanges(pages)
%DISCOVERLABKITCHANGES Load accepted Change records and their reason graph.

    kinds = string({pages.kind});
    selected = find(kinds == "change");
    template = parseTemplate();
    records = repmat(template, numel(selected), 1);
    for k = 1:numel(selected)
        page = pages(selected(k));
        records(k) = parseLabKitChangeRecord( ...
            fileread(page.sourcePath), page.source);
    end
    if isempty(records)
        changes = records;
        return;
    end
    ids = string({records.id});
    if numel(unique(ids)) ~= numel(ids)
        error("LabKit:Docs:DuplicateChangeId", ...
            "Change records contain a duplicate stable ID.");
    end
    changes = records;
    validateReferences(changes);
end

function validateReferences(changes)
    changeIds = string({changes.id});
    for record = changes.'
        requireKnown(record.supersedes, changeIds, ...
            "superseded change", record.source);
        if numel(unique(record.supersedes)) ~= numel(record.supersedes)
            error("LabKit:Docs:DuplicateChangeReference", ...
                "Change %s repeats a superseded Change ID.", record.id);
        end
        if any(record.supersedes == record.id)
            error("LabKit:Docs:CyclicChange", ...
                "Change %s cannot supersede itself.", record.id);
        end
    end
    rejectSupersessionCycles(changes, changeIds);
end

function rejectSupersessionCycles(changes, changeIds)
    state = zeros(numel(changes), 1);
    for k = 1:numel(changes)
        visit(k);
    end

    function visit(index)
        if state(index) == 2
            return;
        end
        if state(index) == 1
            error("LabKit:Docs:CyclicChange", ...
                "Change supersession contains a cycle at %s.", changeIds(index));
        end
        state(index) = 1;
        predecessors = changes(index).supersedes;
        for predecessor = predecessors.'
            visit(find(changeIds == predecessor, 1));
        end
        state(index) = 2;
    end
end

function requireKnown(values, known, label, source)
    missing = values(~ismember(values, known));
    if ~isempty(missing)
        error("LabKit:Docs:UnknownChangeReference", ...
            "%s references unknown %s %s.", source, label, missing(1));
    end
end

function value = parseTemplate()
    value = struct("source", "", "title", "", ...
        "id", "", "date", "", "changeType", "", ...
        "compatibility", "", "components", strings(0, 1), ...
        "supersedes", strings(0, 1));
end
