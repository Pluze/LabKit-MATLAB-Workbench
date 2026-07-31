% Expected caller: figure_studio.resultFiles.exportAxesPackage. Inputs are one
% copied axes and an output folder. Side effects: creates the folder when
% needed and writes plot_data.mat, recreate_plot.m, README.txt, and optional
% plot_data.csv for simple line/scatter object data.
function manifest = writeAxesDataExport(ax, folder)
    folder = string(folder);
    if ~isscalar(folder) || strlength(folder) == 0
        error('figure_studio:resultFiles:InvalidExportFolder', ...
            'Export folder must be nonempty scalar text.');
    end
    if ~isfolder(folder)
        mkdir(folder);
    end

    plotData = figure_studio.resultFiles.extractAxesData(ax);
    matPath = fullfile(folder, "plot_data.mat");
    save(matPath, 'plotData');
    csvPath = writeCsvIfSimple(plotData, folder);
    scriptPath = figure_studio.resultFiles.generateAxesScript(folder, plotData);
    readmePath = writeReadme(plotData, folder, csvPath);

    manifest = struct();
    manifest.folder = folder;
    manifest.mat = string(matPath);
    manifest.csv = csvPath;
    manifest.script = string(scriptPath);
    manifest.readme = string(readmePath);
    manifest.warnings = plotData.warnings;
end

function csvPath = writeCsvIfSimple(plotData, folder)
    csvPath = "";
    if isempty(plotData.objects)
        return;
    end
    types = [plotData.objects.type];
    if ~all(types == "line" | types == "scatter")
        return;
    end

    rows = cell(numel(plotData.objects), 1);
    rowCount = 0;
    for k = 1:numel(plotData.objects)
        object = plotData.objects(k);
        n = min(numel(object.x), numel(object.y));
        if n == 0
            continue;
        end
        one = struct();
        one.objectName = repmat(object.displayName, n, 1);
        one.objectType = repmat(object.type, n, 1);
        one.pointIndex = (1:n).';
        one.x = double(object.x(1:n));
        one.y = double(object.y(1:n));
        if isempty(object.z)
            one.z = nan(n, 1);
        else
            one.z = double(object.z(1:n));
        end
        rowCount = rowCount + 1;
        rows{rowCount, 1} = one;
    end
    rows = rows(1:rowCount);
    if isempty(rows)
        return;
    end
    objectName = vertcatStructField(rows, 'objectName');
    objectType = vertcatStructField(rows, 'objectType');
    pointIndex = vertcatStructField(rows, 'pointIndex');
    x = vertcatStructField(rows, 'x');
    y = vertcatStructField(rows, 'y');
    z = vertcatStructField(rows, 'z');
    tableData = table(objectName, objectType, pointIndex, x, y, z);
    csvPath = string(fullfile(folder, "plot_data.csv"));
    writetable(tableData, csvPath);
end

function readmePath = writeReadme(plotData, folder, csvPath)
    lines = strings(0, 1);
    lines(end + 1, 1) = "LabKit visible plot export";
    lines(end + 1, 1) = "";
    lines(end + 1, 1) = "plot_data.mat is the authoritative visible graphics-object data export.";
    lines(end + 1, 1) = "recreate_plot.m rebuilds the visible plot from plot_data.mat using MATLAB graphics.";
    if strlength(csvPath) > 0
        lines(end + 1, 1) = "plot_data.csv is a convenience export for simple line/scatter data.";
    else
        lines(end + 1, 1) = "plot_data.csv was omitted because the visible objects are not simple line/scatter series.";
    end
    if ~isempty(plotData.warnings)
        lines(end + 1, 1) = "";
        lines(end + 1, 1) = "Warnings:";
        lines = [lines; " - " + plotData.warnings(:)];
    end
    readmePath = fullfile(folder, "README.txt");
    fid = fopen(readmePath, 'w');
    if fid < 0
        error('figure_studio:resultFiles:ExportWriteFailed', ...
            'Could not write export README.');
    end
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, '%s\n', lines);
end

function values = vertcatStructField(rows, field)
    values = cell(size(rows));
    for k = 1:numel(rows)
        values{k} = rows{k}.(field);
    end
    values = vertcat(values{:});
end
