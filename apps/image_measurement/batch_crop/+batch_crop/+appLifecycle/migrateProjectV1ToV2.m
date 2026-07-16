% Expected caller: Runtime V2 project loading. Input is the version-1 Batch
% Crop payload whose task structs may contain decoded image pixels. Output is
% the version-2 durable payload with those session-owned fields removed.
function project = migrateProjectV1ToV2(project)
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
    sources = project.inputs.sources;
    for k = 1:numel(items)
        reference = string(items(k).path);
        sourcePaths = strings(numel(sources), 1);
        for sourceIndex = 1:numel(sources)
            sourcePaths(sourceIndex) = string( ...
                sources(sourceIndex).reference.originalPath);
        end
        match = find(sourcePaths == reference, 1, 'first');
        if isempty(match)
            sourceId = "image" + string(numel(sources) + 1);
            portableReference = labkit.ui.runtime.createPortableFileReference( ...
                "", reference);
            source = struct("id", sourceId, "required", true, ...
                "role", "cropSource", "reference", portableReference);
            sources(end + 1) = source;
        else
            sourceId = string(sources(match).id);
        end
        items(k).sourceId = sourceId;
    end
    project.inputs.items = rmfield(items, 'path');
    project.inputs.sources = sources;
end
