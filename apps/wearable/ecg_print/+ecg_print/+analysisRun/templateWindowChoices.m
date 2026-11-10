function choices = templateWindowChoices(result)
%TEMPLATEWINDOWCHOICES Identify each extraction window by file time and status.
choices = "No windows available";
if isempty(result) || isempty(result.windows), return; end
sourceStart = result.preparation.sourceTimeRangeSeconds(1);
choices = strings(1,numel(result.windows));
for k=1:numel(result.windows)
    w = result.windows(k);
    range = sourceStart+([w.startIndex w.endIndex]-1)/result.fs;
    choices(k) = sprintf('Window %d | File %.3f-%.3f s | %s',k,range,w.status);
end
end
