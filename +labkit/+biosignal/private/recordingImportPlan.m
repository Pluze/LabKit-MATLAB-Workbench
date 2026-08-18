% Private biosignal helper. Expected caller: labkit.biosignal.readRecording.
% Input is a verified file path. Outputs are an ordered direct-call parser plan
% and non-waveform file facts. Side effects: reads MAT directory metadata or at
% most 120 leading text lines; does not load waveform samples.
function [plan, fileInfo] = recordingImportPlan(filepath)
%RECORDINGIMPORTPLAN Rank compatible recording parsers from lightweight facts.

    details = dir(filepath);
    [~, ~, extension] = fileparts(filepath);
    extension = lower(string(extension));
    fileInfo = struct( ...
        'extension', extension, ...
        'bytes', double(details.bytes), ...
        'detectedFormat', "unknown", ...
        'resolvedFormat', "unknown");

    switch extension
        case ".mat"
            variables = whos('-file', filepath);
            names = string({variables.name});
            hasBiopacSignature = all(ismember( ...
                ["data", "isi", "isi_units", "labels", "units"], names));
            hasTimetable = any(string({variables.class}) == "timetable");
            hasTable = any(string({variables.class}) == "table");
            isNumericArray = ismember(string({variables.class}), ...
                ["double", "single", "logical", "int8", "uint8", "int16", ...
                "uint16", "int32", "uint32", "int64", "uint64"]);
            numericArrayCount = nnz(isNumericArray & ...
                arrayfun(@(item) prod(double(item.size)) > 1 && numel(item.size) <= 2, variables));
            if hasBiopacSignature
                fileInfo.detectedFormat = "biopac_mat";
                plan = [candidate("biopac_mat", "mat", @readBiopacMatRecording), ...
                    candidate("timetable_mat", "mat", @readMatRecording), ...
                    candidate("table_mat", "mat", @readTableMatRecording), ...
                    candidate("numeric_mat", "mat", @readNumericMatRecording)];
            elseif hasTimetable
                fileInfo.detectedFormat = "timetable_mat";
                plan = [candidate("timetable_mat", "mat", @readMatRecording), ...
                    candidate("table_mat", "mat", @readTableMatRecording), ...
                    candidate("biopac_mat", "mat", @readBiopacMatRecording), ...
                    candidate("numeric_mat", "mat", @readNumericMatRecording)];
            elseif hasTable
                fileInfo.detectedFormat = "table_mat";
                plan = [candidate("table_mat", "mat", @readTableMatRecording), ...
                    candidate("timetable_mat", "mat", @readMatRecording), ...
                    candidate("biopac_mat", "mat", @readBiopacMatRecording), ...
                    candidate("numeric_mat", "mat", @readNumericMatRecording)];
            else
                if numericArrayCount == 1
                    fileInfo.detectedFormat = "numeric_mat";
                else
                    fileInfo.detectedFormat = "unknown_mat";
                end
                plan = [candidate("numeric_mat", "mat", @readNumericMatRecording), ...
                    candidate("timetable_mat", "mat", @readMatRecording), ...
                    candidate("table_mat", "mat", @readTableMatRecording), ...
                    candidate("biopac_mat", "mat", @readBiopacMatRecording)];
            end
        case {".csv", ".txt", ".tsv"}
            if looksLikeBiopacText(filepath)
                fileInfo.detectedFormat = "biopac_text";
            else
                fileInfo.detectedFormat = "delimited_text";
            end
            plan = candidate("delimited_text", "table", @readCsvRecording);
        otherwise
            error('labkit:biosignal:UnsupportedFile', ...
                'Unsupported biosignal file extension: %s.', extension);
    end
end

function item = candidate(format, kind, reader)
    item = struct('format', string(format), 'kind', string(kind), 'reader', reader);
end

function tf = looksLikeBiopacText(filepath)
    file = fopen(filepath, 'r');
    if file < 0
        error('labkit:biosignal:UnreadableFile', 'Unable to open biosignal text file.');
    end
    cleanup = onCleanup(@() fclose(file));
    hasInterval = false;
    hasChannelCount = false;
    hasTimeHeader = false;
    for k = 1:120
        line = fgetl(file);
        if ~ischar(line)
            break;
        end
        clean = strtrim(line);
        hasInterval = hasInterval || ~isempty(regexp(clean, ...
            '^[+\-]?[0-9.]+\s+[A-Za-z]+/sample$', 'once'));
        hasChannelCount = hasChannelCount || ~isempty(regexp(clean, ...
            '^[0-9]+\s+channels?$', 'once', 'ignorecase'));
        hasTimeHeader = hasTimeHeader || ~isempty(regexp(lower(clean), ...
            '^(sec|time[^,]*),.+', 'once'));
    end
    tf = hasInterval && hasChannelCount && hasTimeHeader;
    clear cleanup
end
