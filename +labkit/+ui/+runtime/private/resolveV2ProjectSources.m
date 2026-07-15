% Private UI runtime helper. Expected caller: restoreV2Project after migration.
% Inputs are a complete project, envelope source records, project path, and app
% project spec. Outputs are a possibly relinked project and resolved source
% records for fresh session cache. Failed/cancelled relinking throws before the
% live runtime changes.
function [project, resolved] = resolveV2ProjectSources( ...
        project, sources, filepath, spec)
    [resolved, unresolved] = resolveRecords(sources, filepath);
    if isempty(unresolved)
        project = applyResolvedPaths(project, resolved);
        return;
    end
    if ~isfield(spec, 'RelinkSources') || ...
            ~isa(spec.RelinkSources, 'function_handle')
        error('labkit:ui:runtime:UnresolvedProjectSources', ...
            'Project has %d unresolved required source(s).', numel(unresolved));
    end
    project = spec.RelinkSources(project, unresolved, string(filepath));
    if isempty(project)
        error('labkit:ui:runtime:ProjectLoadCancelled', ...
            'Project source relinking was cancelled.');
    end
    validateSerializableState(project);
    sources = projectSourceRecords(project, sources);
    [resolved, unresolved] = resolveRecords(sources, filepath);
    if ~isempty(unresolved)
        error('labkit:ui:runtime:UnresolvedProjectSources', ...
            'Project still has unresolved required sources after relinking.');
    end
    project = applyResolvedPaths(project, resolved);
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
        [target, kind] = labkit.ui.runtime.resolvePortableFileReference( ...
            filepath, reference);
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
