function validateLabKitGeneratedLinks(root)
%VALIDATELABKITGENERATEDLINKS Reject missing or escaping generated page links.
% Expected caller: checkLabKitDocs after one complete candidate render.
% Input: root folder of one generated documentation tree.
% Output: none; throws for a local linked target outside or absent from the tree.
% Side effects: reads generated HTML files only.

    files = listLabKitDocTreeFiles(root);
    pages = files(endsWith(files, ".html"));
    for k = 1:numel(pages)
        text = string(fileread(fullfile(root, pages(k))));
        matches = regexp(text, 'href="([^"]+)"', 'tokens');
        for m = 1:numel(matches)
            href = string(matches{m}{1});
            if isExternalOrPageAnchor(href)
                continue;
            end
            path = extractBefore(href + "#", "#");
            path = extractBefore(path + "?", "?");
            if strlength(path) == 0
                continue;
            end
            target = resolveTarget(pages(k), path);
            if ~any(files == target)
                targetLabel = target;
                if ismissing(targetLabel)
                    targetLabel = "<missing>";
                end
                error("LabKit:Docs:BrokenGeneratedLink", ...
                    "Generated page %s links to missing output %s via %s.", ...
                    char(pages(k)), char(targetLabel), char(href));
            end
        end
    end
end

function external = isExternalOrPageAnchor(href)
    external = startsWith(href, ["#", "//"]) || ...
        ~isempty(regexp(char(href), '^[A-Za-z][A-Za-z0-9+.-]*:', 'once'));
end

function target = resolveTarget(source, href)
    href = replace(string(href), "\", "/");
    if startsWith(href, "/")
        base = strings(0, 1);
        href = extractAfter(href, 1);
    else
        folder = replace(string(fileparts(char(source))), "\", "/");
        base = splitPath(folder);
    end
    parts = [base; split(href, "/")];
    normalized = strings(numel(parts), 1);
    count = 0;
    for k = 1:numel(parts)
        part = parts(k);
        if strlength(part) == 0 || part == "."
            continue;
        elseif part == ".."
            if count == 0
                error("LabKit:Docs:GeneratedLinkEscapesSite", ...
                    "Generated page %s has a link outside the site: %s.", ...
                    char(source), char(href));
            end
            count = count - 1;
        else
            count = count + 1;
            normalized(count) = part;
        end
    end
    if count == 0
        target = "";
    else
        target = strjoin(normalized(1:count), "/");
    end
end

function parts = splitPath(path)
    if strlength(path) == 0 || path == "."
        parts = strings(0, 1);
    else
        parts = split(path, "/");
        parts = parts(strlength(parts) > 0);
    end
end
