% Private UI runtime helper. Expected caller: restoreV2Project after migration.
% Inputs are a complete project, envelope source records, project path, and app
% project spec. Outputs are a possibly relinked project and resolved source
% records for fresh session cache. Failed/cancelled relinking throws before the
% live runtime changes.
function [project, resolved, relinked] = resolveV2ProjectSources( ...
        project, sources, filepath, spec, services)
    relinked = false;
    if isempty(sources)
        sources = projectSourceRecords(project, sources);
    end
    [resolved, unresolved] = resolveRecords(sources, filepath);
    if isempty(unresolved)
        project = applyResolvedPaths(project, resolved);
        return;
    end
    if isfield(spec, 'RelinkSources') && ...
            isa(spec.RelinkSources, 'function_handle')
        project = spec.RelinkSources(project, unresolved, string(filepath));
    else
        project = promptForMissingSources( ...
            project, unresolved, string(filepath), services);
    end
    if isempty(project)
        error('labkit:ui:runtime:ProjectLoadCancelled', ...
            'Project source relinking was cancelled.');
    end
    relinked = true;
    validateSerializableState(project);
    sources = projectSourceRecords(project, sources);
    [resolved, unresolved] = resolveRecords(sources, filepath);
    if ~isempty(unresolved)
        error('labkit:ui:runtime:UnresolvedProjectSources', ...
            'Project still has unresolved required sources after relinking.');
    end
    project = applyResolvedPaths(project, resolved);
end

function project = promptForMissingSources( ...
        project, unresolved, projectFile, services)
    for k = 1:numel(unresolved)
        source = unresolved(k);
        sourceId = string(optionValue(source, 'id', "source" + k));
        role = string(optionValue(source, 'role', sourceId));
        reference = optionValue(source, 'reference', struct());
        fileName = string(optionValue(reference, 'fileName', ""));
        if strlength(fileName) == 0
            fileName = "the required file";
        end
        message = sprintf( ...
            ['The saved project cannot find %s for source "%s".\n\n' ...
             'Locate the file to continue loading the project.'], ...
            char(fileName), char(role));
        answer = services.dialogs.choice(message, "Missing project file", ...
            ["Locate file", "Cancel"], "Locate file", "Cancel");
        if answer ~= "Locate file"
            project = [];
            return;
        end
        [selected, cancelled] = services.dialogs.inputFile( ...
            fileFilter(fileName), "Locate " + fileName, ...
            projectFolder(projectFile));
        if cancelled
            project = [];
            return;
        end
        project = replaceSourceReference( ...
            project, sourceId, projectFile, selected);
    end
end

function filter = fileFilter(fileName)
    [~, ~, extension] = fileparts(fileName);
    if strlength(string(extension)) == 0
        filter = {'*.*', 'All files (*.*)'};
        return;
    end
    pattern = "*" + string(extension);
    filter = {char(pattern), char(string(extension) + " files"); ...
        '*.*', 'All files (*.*)'};
end

function folder = projectFolder(projectFile)
    [folder, ~, ~] = fileparts(projectFile);
    if strlength(string(folder)) == 0 || ~isfolder(folder)
        folder = pwd;
    end
end

function project = replaceSourceReference( ...
        project, sourceId, projectFile, selected)
    if ~isfield(project, 'inputs') || ~isstruct(project.inputs) || ...
            ~isfield(project.inputs, 'sources') || ...
            isempty(project.inputs.sources)
        error('labkit:ui:runtime:InvalidProject', ...
            'Project source "%s" cannot be relinked.', sourceId);
    end
    sources = project.inputs.sources;
    match = find(string({sources.id}) == sourceId, 1, 'first');
    if isempty(match)
        error('labkit:ui:runtime:InvalidProject', ...
            'Project source "%s" cannot be relinked.', sourceId);
    end
    sources(match).reference = ...
        createPortableFileReference(projectFile, selected);
    project.inputs.sources = sources;
end

function project = applyResolvedPaths(project, resolved)
    if isempty(resolved) || ~isfield(project, 'inputs') || ...
            ~isstruct(project.inputs) || ...
            ~isfield(project.inputs, 'sources') || ...
            isempty(project.inputs.sources)
        return;
    end
    sources = project.inputs.sources;
    for k = 1:numel(resolved)
        match = find(string({sources.id}) == resolved(k).id, 1, 'first');
        if isempty(match) || ~isfield(sources(match), 'reference') || ...
                ~isstruct(sources(match).reference)
            continue;
        end
        sources(match).reference.originalPath = resolved(k).path;
    end
    project.inputs.sources = sources;
end

function [resolved, unresolved] = resolveRecords(sources, filepath)
    resolved = struct("id", {}, "path", {}, "matchKind", {});
    unresolved = struct([]);
    if isempty(sources)
        return;
    end
    if ~isstruct(sources)
        error('labkit:ui:runtime:InvalidProject', ...
            'Project sources must be a struct array.');
    end
    for k = 1:numel(sources)
        source = sources(k);
        id = string(optionValue(source, 'id', "source" + k));
        reference = optionValue(source, 'reference', struct());
        [target, kind] = resolvePortableFileReference(filepath, reference);
        if strlength(target) > 0
            resolved(end + 1) = struct( ...
                "id", id, "path", target, "matchKind", kind);
        elseif logical(optionValue(source, 'required', false))
            if isempty(unresolved)
                unresolved = source;
            else
                unresolved(end + 1) = source;
            end
        end
    end
end

function sources = projectSourceRecords(project, fallback)
    sources = fallback;
    if isfield(project, 'inputs') && isstruct(project.inputs) && ...
            isfield(project.inputs, 'sources')
        sources = project.inputs.sources;
    end
end

function value = optionValue(spec, name, defaultValue)
    value = defaultValue;
    if isstruct(spec) && isfield(spec, name)
        value = spec.(name);
    end
end
