function writeMesurGaugeLog(filepath, time_s, loadValue, travelValue, ...
        loadUnit, travelUnit, startedAt)
%WRITEMESURGAUGELOG Write the tab-delimited MESUR gauge exchange format.
time_s = double(time_s(:));
loadValue = double(loadValue(:));
travelValue = double(travelValue(:));
if numel(time_s) ~= numel(loadValue) || numel(time_s) ~= numel(travelValue)
    error("mark10_monitor:InvalidRecording", ...
        "MESUR gauge log columns must have equal lengths.");
end
fileId = fopen(filepath, "w");
if fileId < 0
    error("mark10_monitor:ExportFailed", ...
        "Could not open the MESUR gauge log for writing.");
end
cleanup = onCleanup(@() fclose(fileId));
fprintf(fileId, "%s\r\n", timestampText(startedAt));
fprintf(fileId, "Units: %s\r\n", char(loadUnit));
fprintf(fileId, "Readings: Continuous\r\n");
fprintf(fileId, "X-Axis: Travel\r\n");
fprintf(fileId, "Travel Unit: %s\r\n", char(travelUnit));
fprintf(fileId, "Reading\tLoad\tTravel\tTime\r\n");
for index = 1:numel(time_s)
    fprintf(fileId, "%d\t%.2f\t%.3f\t%.3f\r\n", index, ...
        loadValue(index), travelValue(index), time_s(index));
end
clear cleanup
end

function text = timestampText(value)
hour = value.Hour;
suffix = "AM";
if hour >= 12, suffix = "PM"; end
hour = mod(hour, 12);
if hour == 0, hour = 12; end
text = sprintf("%d/%d/%d  %d:%02d %s", value.Month, value.Day, ...
    value.Year, hour, value.Minute, suffix);
end
