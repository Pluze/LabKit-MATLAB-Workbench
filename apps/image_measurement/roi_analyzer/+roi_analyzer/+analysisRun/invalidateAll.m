function results = invalidateAll(results)
%INVALIDATEALL Clear measurements after shared analysis meaning changes.
for k = 1:numel(results.items)
    results.items(k).roiFingerprint = "";
    results.items(k).summary = table();
    results.items(k).metrics = table();
end
results.lastExportPath = "";
results.batchStatus = table();
end
