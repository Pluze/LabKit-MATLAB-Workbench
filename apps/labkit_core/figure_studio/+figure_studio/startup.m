% Expected caller: the LabKit V2 runtime Start hook. Output adopts a plain
% axes-handoff snapshot and registers preview resize resources outside state.
function state = startup(state, ~, services)
    if strlength(state.project.parameters.outputFolder) == 0
        state.project.parameters.outputFolder = string( ...
            services.dialogs.defaultFolder("output"));
    end
    launch = struct("hasAxes", false);
    if isstruct(services.request) && isfield(services.request, 'launch')
        launch = services.request.launch;
    end
    if isstruct(launch) && isfield(launch, 'hasAxes') && launch.hasAxes
        state.project.inputs.sources = state.project.inputs.sources([]);
        state.project.annotations.embeddedPlot = launch.plotData;
        state.project.annotations.sourceDefaultStyle = launch.sourceStyle;
        state.session.cache.plotData = launch.plotData;
        state.session.cache.sourceDefaultStyle = launch.sourceStyle;
        state.session.cache.currentSource = "Popout axes";
        state = adoptSourceStyle(state, launch.sourceStyle);
        state.session.workflow.status = "Received copied axes from popout.";
        state = services.workflow.log(state, ...
            "Received axes from popout window.");
    end
    ax = services.previews.axes("preview", "main");
    resource = figure_studio.userInterface.installPreviewResize(ax);
    services.resources.set("session", "figureStudioResize", resource, ...
        @figure_studio.userInterface.cleanupPreviewResize);
    if services.debug.enabled
        state = services.workflow.log(state, ...
            "Figure Studio debug trace enabled.");
    end
end

function state = adoptSourceStyle(state, sourceStyle)
    state.project.annotations.sourceDefaultStyle = sourceStyle;
    if state.project.parameters.preset == "FIG default"
        state.project.parameters.style = sourceStyle;
    else
        state.project.parameters.style.canvasWidth = sourceStyle.canvasWidth;
        state.project.parameters.style.canvasHeight = sourceStyle.canvasHeight;
        state.project.parameters.aspectPreset = "Custom";
    end
end
