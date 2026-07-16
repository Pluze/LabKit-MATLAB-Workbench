function html = renderLabKitHistorySequenceNavigation(model, page)
%RENDERLABKITHISTORYSEQUENCENAVIGATION Link adjacent change records.
% Expected caller: renderLabKitDocs narrative-page generation.
% Inputs: documentation model and current narrative page metadata.
% Output: bottom-of-page navigation for history records, otherwise empty.
% Side effects: none. Adjacency follows validated sequence metadata.

    html = "";
    if page.kind ~= "history" || isempty(model.history)
        return;
    end

    history = model.history;
    sequences = [history.historySequence];
    current = page.historySequence;
    previousIndex = find(sequences == current - 1, 1);
    nextIndex = find(sequences == current + 1, 1);
    links = strings(0, 1);
    if ~isempty(previousIndex)
        links(end + 1, 1) = adjacentLink(page.output, ...
            history(previousIndex), "Previous change", "older");
    end
    if ~isempty(nextIndex)
        links(end + 1, 1) = adjacentLink(page.output, ...
            history(nextIndex), "Next change", "newer");
    end
    if isempty(links)
        return;
    end

    html = "<nav class=""history-sequence-nav"" " + ...
        "aria-label=""Adjacent history records"">" + ...
        strjoin(links, "") + "</nav>";
end

function html = adjacentLink(currentOutput, item, direction, chronology)
    html = "<a class=""history-sequence-link " + chronology + ...
        """ href=""" + relativeWebPath(currentOutput, item.output) + ...
        """><span>" + direction + "</span><strong>" + ...
        htmlEscape(item.title) + "</strong></a>";
end

function text = htmlEscape(text)
    text = replace(string(text), "&", "&amp;");
    text = replace(text, "<", "&lt;");
    text = replace(text, ">", "&gt;");
    text = replace(text, """", "&quot;");
end
