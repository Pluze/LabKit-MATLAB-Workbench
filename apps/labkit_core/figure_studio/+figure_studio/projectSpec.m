%PROJECTSPEC Declare Figure Studio's durable project contract.
% Expected caller: figure_studio.definition. Output owns the current payload
% version plus local create and validation callbacks. Side effects are none.
function spec = projectSpec()
    spec = labkit.app.project.Schema(Version=4, ...
        Create=@createProject, Validate=@validateProject, ...
        Migrate=@migrateProject, SourceBindings="inputs.sources");
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
        "aspectPreset", "Reference", ...
        "canvasSize", "900 px", ...
        "gridChoice", onOff(style.gridVisible), ...
        "boundaryChoice", onOff(style.boundaryLines), ...
        "outputFolder", "");
    project.annotations = struct( ...
        "embeddedPlot", [], ...
        "sourceDefaultStyle", style, ...
        "limitOverrides", emptyLimitOverrides(), ...
        "panelIndex", 1);
    project.results = struct( ...
        "lastExport", [], ...
        "resultManifestPath", "");
    project.extensions = struct();
end

function accepted = validateProject(project)
    assert(isfield(project.inputs, 'sources'), ...
        'figure_studio:InvalidProject', 'Project sources are invalid.');
    fields = {'preset', 'style', 'aspectPreset', 'canvasSize', 'gridChoice', ...
        'boundaryChoice', 'outputFolder'};
    assert(all(isfield(project.parameters, fields)) && ...
        isstruct(project.parameters.style), ...
        'figure_studio:InvalidProject', 'Project style parameters are invalid.');
    assert(all(isfield(project.annotations, ...
        {'embeddedPlot', 'sourceDefaultStyle', 'limitOverrides', 'panelIndex'})), ...
        'figure_studio:InvalidProject', 'Project plot annotations are invalid.');
    accepted = true;
end

function project = migrateProject(project, fromVersion)
    if ~any(fromVersion == [1 2 3])
        error("figure_studio:UnsupportedProjectVersion", ...
            "Figure Studio cannot migrate project schema version %d.", ...
            fromVersion);
    end
    if fromVersion == 1
        defaults = versionOneStyleDefaults(project.parameters.preset);
        savedStyle = project.parameters.style;
        project.parameters.style = mergeStyle( ...
            defaults, savedStyle);
        project.parameters.style = completeVersionOneGeometry( ...
            project.parameters.style, defaults);
        project.parameters.style = legacyReferenceCanvas( ...
            project.parameters.style, savedStyle);
        savedSourceStyle = project.annotations.sourceDefaultStyle;
        project.annotations.sourceDefaultStyle = mergeStyle( ...
            defaults, savedSourceStyle);
        project.annotations.sourceDefaultStyle = completeVersionOneGeometry( ...
            project.annotations.sourceDefaultStyle, defaults);
        project.annotations.sourceDefaultStyle = legacyReferenceCanvas( ...
            project.annotations.sourceDefaultStyle, savedSourceStyle);
    end
    if project.parameters.aspectPreset == "Custom"
        project.parameters.aspectPreset = "Source";
    end
    if fromVersion < 3
        project.parameters.canvasSize = "Source size";
    end
    if ~isfield(project.annotations, "limitOverrides")
        project.annotations.limitOverrides = emptyLimitOverrides();
    end
    if ~isfield(project.annotations, "panelIndex")
        project.annotations.panelIndex = 1;
    end
end

function style = completeVersionOneGeometry(style, defaults)
position = double(style.axesPosition);
if numel(position) ~= 4 || any(~isfinite(position)) || ...
        position(3) <= 0 || position(4) <= 0
    style.axesPosition = defaults.axesPosition;
end
end

function style = versionOneStyleDefaults(preset)
% Version-one projects did not persist every style category. Complete only
% their missing fields with that schema's defaults so a saved publication
% style is never silently restyled by the current reference profile.
style = figure_studio.styleLibrary.styleForPreset(preset);
if string(preset) ~= "LabKit figure"
    return;
end
style.baseFontSize = 20;
style.titleFontSize = 60;
style.labelFontSize = 72;
style.tickFontSize = 60;
style.annotationFontSize = 54;
style.legendFontSize = 64;
style.dataLineWidth = 6.0;
style.uncertaintyLineWidth = 4.0;
style.boundaryLineWidth = 2.5;
style.referenceLineWidth = 4.0;
style.axesLineWidth = 2.4;
style.canvasWidth = 1600;
style.canvasHeight = 1333;
style.referenceCanvasWidth = 1600;
style.referenceCanvasHeight = 1333;
style.axesPosition = [0.185 0.17 0.795 0.78];
end

function limits = emptyLimitOverrides()
limits = struct("xLim", [], "yLim", []);
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
