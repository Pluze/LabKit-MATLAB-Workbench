% Private Runtime V2 serialization helper. Expected caller: project-envelope
% creation. Inputs are durable project data and the actual destination MAT
% path. Output copies the project and refreshes standard portable-reference
% fields while preserving app-owned additive reference fields.
function project = rebaseProjectSources(project, filepath)
    if strlength(string(filepath)) == 0 || ...
            ~isfield(project, 'inputs') || ~isstruct(project.inputs) || ...
            ~isfield(project.inputs, 'sources') || isempty(project.inputs.sources)
        return;
    end
    sources = project.inputs.sources;
    for k = 1:numel(sources)
        if ~isfield(sources(k), 'reference') || ...
                ~isstruct(sources(k).reference) || ...
                ~isscalar(sources(k).reference) || ...
                ~isfield(sources(k).reference, 'originalPath')
            continue;
        end
        target = string(sources(k).reference.originalPath);
        portable = labkit.ui.runtime.createPortableFileReference( ...
            filepath, target);
        reference = sources(k).reference;
        standardFields = fieldnames(portable);
        for fieldIndex = 1:numel(standardFields)
            name = standardFields{fieldIndex};
            reference.(name) = portable.(name);
        end
        sources(k).reference = reference;
    end
    project.inputs.sources = sources;
end
