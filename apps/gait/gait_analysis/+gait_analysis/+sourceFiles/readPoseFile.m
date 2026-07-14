%READPOSEFILE Read pose coordinates from CSV or MAT into a normalized shape.
% Expected caller: app load action and tests. Supported CSV layouts include
% LabKit marker CSV, LabKit coordinate CSV, and generic wide tables with
% point_x/point_y or point__x/point__y columns. MAT files may contain either
% a pose struct or coords plus pointNames variables.
function pose = readPoseFile(filepath)
    filepath = string(filepath);
    if strlength(filepath) == 0 || exist(filepath, "file") ~= 2
        error('labkit_GaitAnalysis_app:PoseFileNotFound', ...
            'Pose coordinate file was not found.');
    end

    [~, ~, ext] = fileparts(filepath);
    ext = lower(string(ext));
    if ext == ".csv" || ext == ".txt" || ext == ".tsv"
        pose = readPoseCsv(filepath);
    elseif ext == ".mat"
        pose = readPoseMat(filepath);
    else
        error('labkit_GaitAnalysis_app:UnsupportedPoseFile', ...
            'Supported pose input formats are CSV, TXT, TSV, and MAT.');
    end
    pose.sourcePath = filepath;
    pose.ok = true;
end

function pose = readPoseCsv(filepath)
    delimiter = delimiterForFile(filepath);
    T = readtable(filepath, "FileType", "text", ...
        "CommentStyle", "#", "Delimiter", delimiter, ...
        "TextType", "string", "VariableNamingRule", "preserve");
    if height(T) == 0
        error('labkit_GaitAnalysis_app:EmptyPoseTable', ...
            'Pose coordinate table is empty.');
    end

    varNames = string(T.Properties.VariableNames);
    columns = detectCoordinateColumns(varNames);
    if isempty(columns.pointNames)
        error('labkit_GaitAnalysis_app:MissingCoordinateColumns', ...
            'Pose table must contain paired X/Y columns for at least one point.');
    end

    frameCount = height(T);
    pointCount = numel(columns.pointNames);
    coords = NaN(frameCount, pointCount, 2);
    for p = 1:pointCount
        coords(:, p, 1) = numericColumn(T, columns.xNames(p));
        coords(:, p, 2) = numericColumn(T, columns.yNames(p));
    end

    pose = gait_analysis.sourceFiles.emptyPoseData();
    pose.sourceFormat = "csv";
    pose.pointNames = columns.pointNames(:);
    pose.coords = coords;
    pose.frameIndex = frameIndexFromTable(T, frameCount);
    pose.time = timeFromTable(T, frameCount);
    pose.unitName = unitFromTable(T, columns);
end

function pose = readPoseMat(filepath)
    raw = load(filepath);
    if isfield(raw, "pose")
        pose = normalizePoseStruct(raw.pose);
        pose.sourceFormat = "mat.pose";
        return;
    end
    if isfield(raw, "poseData")
        pose = normalizePoseStruct(raw.poseData);
        pose.sourceFormat = "mat.poseData";
        return;
    end
    if ~isfield(raw, "coords") || ~isfield(raw, "pointNames")
        error('labkit_GaitAnalysis_app:InvalidPoseMat', ...
            'MAT pose files must contain pose, poseData, or coords plus pointNames.');
    end
    pose = gait_analysis.sourceFiles.emptyPoseData();
    pose.sourceFormat = "mat.coords";
    pose.coords = double(raw.coords);
    pose.pointNames = string(raw.pointNames(:));
    pose.frameIndex = optionalVector(raw, "frameIndex", size(pose.coords, 1));
    pose.time = optionalVector(raw, "time", size(pose.coords, 1));
    pose.unitName = optionalString(raw, "unitName", "px");
    pose = validatePose(pose);
end

function pose = normalizePoseStruct(raw)
    pose = gait_analysis.sourceFiles.emptyPoseData();
    pose.coords = double(raw.coords);
    pose.pointNames = string(raw.pointNames(:));
    pose.frameIndex = optionalVector(raw, "frameIndex", size(pose.coords, 1));
    pose.time = optionalVector(raw, "time", size(pose.coords, 1));
    pose.unitName = optionalString(raw, "unitName", "px");
    pose = validatePose(pose);
end

function pose = validatePose(pose)
    if ndims(pose.coords) ~= 3 || size(pose.coords, 3) ~= 2
        error('labkit_GaitAnalysis_app:InvalidPoseShape', ...
            'Pose coordinates must be frame-by-point-by-2.');
    end
    if size(pose.coords, 2) ~= numel(pose.pointNames)
        error('labkit_GaitAnalysis_app:InvalidPoseShape', ...
            'Point name count must match coordinate point count.');
    end
    frameCount = size(pose.coords, 1);
    if isempty(pose.frameIndex)
        pose.frameIndex = (1:frameCount).';
    end
    if isempty(pose.time)
        pose.time = NaN(frameCount, 1);
    end
    pose.frameIndex = double(pose.frameIndex(:));
    pose.time = double(pose.time(:));
    if numel(pose.frameIndex) ~= frameCount || numel(pose.time) ~= frameCount
        error('labkit_GaitAnalysis_app:InvalidPoseShape', ...
            'Frame index and time vectors must match the frame count.');
    end
    pose.ok = true;
end

function delimiter = delimiterForFile(filepath)
    [~, ~, ext] = fileparts(filepath);
    if lower(string(ext)) == ".tsv"
        delimiter = "\t";
    else
        delimiter = ",";
    end
end

function columns = detectCoordinateColumns(varNames)
    pointNames = strings(0, 1);
    xNames = strings(0, 1);
    yNames = strings(0, 1);
    for k = 1:numel(varNames)
        [pointName, axisName] = parseCoordinateColumn(varNames(k));
        if axisName ~= "x"
            continue;
        end
        if any(pointNames == pointName)
            continue;
        end
        yName = pairedYColumn(varNames, pointName, varNames(k));
        if yName == ""
            continue;
        end
        pointNames(end+1, 1) = pointName;
        xNames(end+1, 1) = varNames(k);
        yNames(end+1, 1) = yName;
    end
    columns = struct("pointNames", pointNames, "xNames", xNames, "yNames", yNames);
end

function [pointName, axisName] = parseCoordinateColumn(varName)
    text = char(varName);
    tokens = regexp(text, '^(.+)__(x|y)(_px)?$', 'tokens', 'once');
    if isempty(tokens)
        tokens = regexp(text, '^(.+)_(x|y)(_px)?$', 'tokens', 'once');
    end
    if isempty(tokens)
        tokens = regexp(text, '^(x|y)_(.+)$', 'tokens', 'once');
        if isempty(tokens)
            pointName = "";
            axisName = "";
        else
            pointName = string(tokens{2});
            axisName = string(tokens{1});
        end
    else
        pointName = string(tokens{1});
        axisName = string(tokens{2});
    end
end

function yName = pairedYColumn(varNames, pointName, xName)
    candidates = [
        pointName + "__y_px"
        pointName + "__y"
        pointName + "_y_px"
        pointName + "_y"
        "y_" + pointName];
    yName = "";
    for k = 1:numel(candidates)
        if any(varNames == candidates(k)) && xName ~= candidates(k)
            yName = candidates(k);
            return;
        end
    end
end

function values = numericColumn(T, varName)
    raw = T.(char(varName));
    if isnumeric(raw)
        values = double(raw);
    else
        values = str2double(string(raw));
    end
    values = values(:);
end

function frames = frameIndexFromTable(T, frameCount)
    if any(string(T.Properties.VariableNames) == "frame_index")
        frames = numericColumn(T, "frame_index");
    elseif any(string(T.Properties.VariableNames) == "frame")
        frames = numericColumn(T, "frame");
    else
        frames = (1:frameCount).';
    end
end

function time = timeFromTable(T, frameCount)
    if any(string(T.Properties.VariableNames) == "time_s")
        time = numericColumn(T, "time_s");
    elseif any(string(T.Properties.VariableNames) == "time")
        time = numericColumn(T, "time");
    else
        time = NaN(frameCount, 1);
    end
end

function unitName = unitFromTable(T, columns)
    if all(endsWith(columns.xNames, "_px")) && all(endsWith(columns.yNames, "_px"))
        unitName = "px";
        return;
    end
    unitName = "px";
    if any(string(T.Properties.VariableNames) == "coordinate_unit")
        values = string(T.coordinate_unit);
        values = values(strlength(values) > 0);
        if ~isempty(values)
            unitName = values(1);
        end
    end
end

function values = optionalVector(raw, fieldName, frameCount)
    fieldName = char(fieldName);
    if isstruct(raw) && isfield(raw, fieldName)
        values = double(raw.(fieldName)(:));
    else
        values = NaN(frameCount, 1);
    end
end

function value = optionalString(raw, fieldName, fallback)
    fieldName = char(fieldName);
    if isstruct(raw) && isfield(raw, fieldName)
        value = string(raw.(fieldName));
    else
        value = string(fallback);
    end
end
