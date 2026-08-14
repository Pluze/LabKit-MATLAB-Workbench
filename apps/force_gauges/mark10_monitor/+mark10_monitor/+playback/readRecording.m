function recording = readRecording(filepath)
%READRECORDING Read App CSV, MESUR gauge LOG, or complete App MAT data.
[~, ~, extension] = fileparts(filepath);
switch lower(string(extension))
    case ".csv"
        tableData = readtable(filepath);
        requireColumns(tableData, ["Time_s", "Force_N", "Travel_mm"]);
        recording = result(tableData.Time_s, tableData.Force_N, ...
            tableData.Travel_mm, "Standard CSV");
    case ".log"
        recording = readLog(filepath);
    case ".mat"
        loaded = load(filepath, "recording");
        if ~isfield(loaded, "recording") || ...
                ~isstruct(loaded.recording) || ~isscalar(loaded.recording)
            invalid("MAT file does not contain one recording struct");
        end
        value = loaded.recording;
        names = ["Time_s", "Force_N", "Travel_mm"];
        if ~all(isfield(value, names))
            invalid("MAT recording is missing Time_s, Force_N, or Travel_mm");
        end
        valid = true(numel(value.Time_s), 1);
        if isfield(value, "Valid")
            valid = logical(value.Valid(:));
        end
        recording = result(value.Time_s(valid), value.Force_N(valid), ...
            value.Travel_mm(valid), "Complete MAT");
    otherwise
        invalid("file extension must be .csv, .log, or .mat");
end
end

function recording = readLog(filepath)
lines = readlines(filepath, "EmptyLineRule", "skip");
delimiter = string(char(9));
if numel(lines) < 7 || strip(lines(6)) ~= ...
        "Reading" + delimiter + "Load" + delimiter + ...
        "Travel" + delimiter + "Time"
    invalid("MESUR gauge LOG header is unsupported");
end
loadUnit = strip(extractAfter(lines(2), "Units:"));
travelUnit = strip(extractAfter(lines(5), "Travel Unit:"));
rows = split(lines(7:end), delimiter);
if size(rows, 2) ~= 4
    invalid("MESUR gauge LOG data rows must have four tab-delimited columns");
end
loadValue = str2double(rows(:, 2));
travelValue = str2double(rows(:, 3));
time = str2double(rows(:, 4));
forceN = NaN(size(loadValue));
travelMm = NaN(size(travelValue));
for index = 1:numel(time)
    sample = labkit.mark10.decodeSample(compose("%.12g %s\n%.12g %s", ...
        loadValue(index), loadUnit, travelValue(index), travelUnit));
    forceN(index) = sample.Force_N;
    travelMm(index) = sample.Travel_mm;
end
recording = result(time, forceN, travelMm, "MESUR gauge LOG");
end

function requireColumns(value, names)
if ~all(ismember(names, string(value.Properties.VariableNames)))
    invalid("CSV must contain Time_s, Force_N, and Travel_mm columns");
end
end

function value = result(time, force, travel, format)
time = double(time(:));
force = double(force(:));
travel = double(travel(:));
if isempty(time) || numel(time) ~= numel(force) || ...
        numel(time) ~= numel(travel) || any(~isfinite(time)) || ...
        any(~isfinite(force)) || any(~isfinite(travel)) || ...
        any(diff(time) < 0)
    invalid("recording columns must be nonempty, finite, equal-length, and time ordered");
end
time = time - time(1);
value = struct("Time_s", time, "Force_N", force, ...
    "Travel_mm", travel, "Format", string(format));
end

function invalid(message)
error("mark10_monitor:InvalidRecording", "Mark-10 %s.", message);
end
