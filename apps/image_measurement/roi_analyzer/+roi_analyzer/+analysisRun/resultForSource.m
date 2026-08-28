function result = resultForSource(items, sourceId)
%RESULTFORSOURCE Return current measurements for one source identity.
match = find(string({items.sourceId}) == string(sourceId), 1);
if isempty(match)
    result = struct("sourceId", string(sourceId), ...
        "roiFingerprint", "", "summary", table(), "metrics", table());
else
    result = items(match);
end
end
