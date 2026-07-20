%PROJECTSPEC Declare Figure Studio's durable project contract.
% Expected caller: figure_studio.definition. Output owns the current payload
% version plus local create and validation callbacks. Side effects are none.
function spec = projectSpec()
    spec = labkit.app.project.Schema(Version=2, ...
        Create=@createProject, Validate=@validateProject, ...
        Migrate=@migrateProject);
end

function project = createProject()
    preset = "LabKit figure";
    style = figure_studio.styleLibrary.styleForPreset(preset);
    project = struct();
    project.inputs = struct("sources", ...
        struct([]));
    project.parameters = struct( ...
        "preset", preset, ...
        "style", style, ...
        "aspectPreset", "6:5", ...
        "gridChoice", onOff(style.gridVisible), ...
        "boundaryChoice", onOff(style.boundaryLines), ...
        "outputFolder", "");
    project.annotations = struct( ...
        "embeddedPlot", [], ...
        "sourceDefaultStyle", style);
    project.results = struct( ...
        "lastExport", [], ...
        "resultManifestPath", "");
    project.extensions = struct();
end

function accepted = validateProject(project)
    assert(isfield(project.inputs, 'sources'), ...
        'figure_studio:InvalidProject', 'Project sources are invalid.');
    fields = {'preset', 'style', 'aspectPreset', 'gridChoice', ...
        'boundaryChoice', 'outputFolder'};
    assert(all(isfield(project.parameters, fields)) && ...
        isstruct(project.parameters.style), ...
        'figure_studio:InvalidProject', 'Project style parameters are invalid.');
    assert(all(isfield(project.annotations, ...
        {'embeddedPlot', 'sourceDefaultStyle'})), ...
        'figure_studio:InvalidProject', 'Project plot annotations are invalid.');
    accepted = true;
end

function project = migrateProject(project, fromVersion)
    if fromVersion ~= 1
        error("figure_studio:UnsupportedProjectVersion", ...
            "Figure Studio cannot migrate project schema version %d.", ...
            fromVersion);
    end
    defaults = figure_studio.styleLibrary.styleForPreset( ...
        project.parameters.preset);
    savedStyle = project.parameters.style;
    project.parameters.style = mergeStyle( ...
        defaults, savedStyle);
    project.parameters.style = legacyReferenceCanvas( ...
        project.parameters.style, savedStyle);
    savedSourceStyle = project.annotations.sourceDefaultStyle;
    project.annotations.sourceDefaultStyle = mergeStyle( ...
        defaults, savedSourceStyle);
    project.annotations.sourceDefaultStyle = legacyReferenceCanvas( ...
        project.annotations.sourceDefaultStyle, savedSourceStyle);
end

function style = mergeStyle(defaults, saved)
    style = defaults;
    if ~isstruct(saved) || ~isscalar(saved)
        return;
    end
    names = fieldnames(saved);
    for k = 1:numel(names)
        style.(names{k}) = saved.(names{k});
    end
end

function style = legacyReferenceCanvas(style, saved)
    if ~isstruct(saved) || ~isscalar(saved)
        return;
    end
    if ~isfield(saved, 'referenceCanvasWidth') && ...
            isfield(saved, 'canvasWidth')
        style.referenceCanvasWidth = saved.canvasWidth;
    end
    if ~isfield(saved, 'referenceCanvasHeight') && ...
            isfield(saved, 'canvasHeight')
        style.referenceCanvasHeight = saved.canvasHeight;
    end
end

function value = onOff(tf)
    if tf
        value = "On";
    else
        value = "Off";
    end
end
