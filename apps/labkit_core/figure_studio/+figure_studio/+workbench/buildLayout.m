function layout = buildLayout()
controls = {labkit.app.layout.tab("figures", "Figures", { ...
    figure_studio.sourceAxes.layoutSection(), figure_studio.styleLibrary.layoutSection(), figure_studio.resultFiles.layoutSection()}), ...
    labkit.app.layout.tab("log", "Log", {labkit.app.layout.logPanel("appLog")})};
workspace = labkit.app.layout.workspace(labkit.app.layout.plotArea("preview", @figure_studio.sourceAxes.drawPreview));
layout = labkit.app.layout.workbench(controls, Workspace=workspace);
end
