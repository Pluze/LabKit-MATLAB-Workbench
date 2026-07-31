% App-owned durable Batch Crop contract. The App SDK calls the one-step
% migration entry for older payloads, then validates the version-3
% one-task-per-source structure.
function spec = projectSpec()
    spec = labkit.app.project.Schema(Version=3, ...
        Create=@createProject, Validate=@validateProject, ...
        Migrate=@migrateProject, SourceBindings="inputs.sources");
end

function project = createProject()
    project = struct();
    project.inputs = struct( ...
        "sources", emptySources(), ...
        "items", repmat(batch_crop.cropTasks.emptyTask(), 0, 1));
    project.parameters = struct( ...
        "cropWidth", 1024, ...
        "cropHeight", 1024, ...
        "scaleMode", "Pixels", ...
        "scaleUnit", "um", ...
        "physicalWidth", 100, ...
        "physicalHeight", 100, ...
        "targetPixelsPerUnit", 0, ...
        "maxUpsamplePercent", 15, ...
        "format", "PNG", ...
        "outputFolder", "", ...
        "scaleBarLength", 100, ...
        "scaleBarPosition", "Bottom right", ...
        "scaleBarColor", "Black");
    project.annotations = struct();
    project.results = struct( ...
        "lastExport", [], ...
        "lastExportFingerprint", "", ...
        "resultManifestPath", "");
    project.extensions = struct();
end

function sources = emptySources()
reference = struct("schemaVersion", 1, "relativePath", "", ...
    "originalPath", "", "fileName", "");
prototype = struct("id", "", "required", true, "role", "", ...
    "reference", {reference});
sources = repmat(prototype, 0, 1);
end

function project = migrateProject(project, fromVersion)
    switch double(fromVersion)
        case 1
            project = migrateVersionOne(project);
        case 2
            project = migrateVersionTwo(project);
        otherwise
            error('batch_crop:UnsupportedProjectMigration', ...
                'Batch Crop cannot migrate project version %d.', fromVersion);
    end
end

function project = migrateVersionTwo(project)
if ~isfield(project, 'inputs') || ...
        ~isfield(project.inputs, 'items') || ...
        ~isfield(project.inputs, 'sources') || ...
        isempty(project.inputs.items)
    return
end
items = project.inputs.items;
sources = project.inputs.sources;
taskSources = emptySources();
usedSourceIds = strings(0, 1);
for k = 1:numel(items)
    match = find(string({sources.id}) == string(items(k).sourceId), 1);
    if isempty(match)
        continue
    end
    source = sources(match);
    sourceId = string(source.id);
    if any(usedSourceIds == sourceId)
        sourceId = nextSourceId(sources, taskSources);
        source.id = sourceId;
        items(k).sourceId = sourceId;
    end
    if isempty(taskSources)
        taskSources = source;
    else
        taskSources(end + 1, 1) = source;
    end
    usedSourceIds(end + 1, 1) = sourceId;
end
project.inputs.items = items;
project.inputs.sources = taskSources;
end

function id = nextSourceId(existing, pending)
ids = [string({existing.id}), string({pending.id})];
number = 1;
id = "image-" + string(number);
while any(ids == id)
    number = number + 1;
    id = "image-" + string(number);
end
end

function project = migrateVersionOne(project)
    if isfield(project, 'inputs') && isfield(project.inputs, 'items') && ...
            isstruct(project.inputs.items) && ...
            isfield(project.inputs.items, 'image')
        project.inputs.items = rmfield(project.inputs.items, 'image');
    end
    if ~isfield(project, 'inputs') || ~isfield(project.inputs, 'items') || ...
            isempty(project.inputs.items) || ...
            ~isfield(project.inputs.items, 'path')
        return;
    end
    items = project.inputs.items;
    sources = struct([]);
    sourcePaths = strings(0, 1);
    for k = 1:numel(items)
        path = string(items(k).path);
        match = find(sourcePaths == path, 1, 'first');
        if isempty(match)
            sourceId = "image" + string(numel(sources) + 1);
            source = labkit.app.project.sourceRecord( ...
                sourceId, "cropSource", path, true);
            if isempty(sources)
                sources = source;
            else
                sources(end + 1, 1) = source;
            end
            sourcePaths(end + 1, 1) = path;
        else
            sourceId = string(sources(match).id);
        end
        items(k).sourceId = sourceId;
    end
    project.inputs.items = rmfield(items, 'path');
    project.inputs.sources = sources;
end

function accepted = validateProject(project)
    assert(isfield(project.inputs, 'items') && ...
        isfield(project.inputs, 'sources'), ...
        'batch_crop:InvalidProject', ...
        'Batch crop project inputs must contain items and sources.');
    items = project.inputs.items;
    sources = project.inputs.sources;
    assert(isstruct(items), 'batch_crop:InvalidProject', ...
        'Batch crop project items must be a struct array.');
    requiredItemFields = ["sourceId", "angleDeg", ...
        "paddingPercent", "centerXY", "centerSet", "scaleCalibration"];
    assert(isempty(items) || all(isfield(items, cellstr(requiredItemFields))), ...
        'batch_crop:InvalidProject', ...
        'Batch crop project items do not match the crop-task contract.');
    sourceIds = reshape(string({sources.id}), 1, []);
    taskSourceIds = reshape(string({items.sourceId}), 1, []);
    assert(numel(items) == numel(sources) && ...
        isequal(taskSourceIds, sourceIds), ...
        'batch_crop:InvalidProject', ...
        ['Every crop task must align with one distinct portable ' ...
         'source record.']);
    requiredParameters = ["cropWidth", "cropHeight", "scaleMode", ...
        "scaleUnit", "physicalWidth", "physicalHeight", ...
        "targetPixelsPerUnit", "maxUpsamplePercent", "format", ...
        "outputFolder", "scaleBarLength", "scaleBarPosition", ...
        "scaleBarColor"];
    assert(all(isfield(project.parameters, cellstr(requiredParameters))), ...
        'batch_crop:InvalidProject', ...
        'Batch crop project parameters are incomplete.');
    accepted = true;
end
