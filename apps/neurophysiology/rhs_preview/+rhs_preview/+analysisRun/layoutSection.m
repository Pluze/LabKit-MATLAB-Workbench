function section = layoutSection()
section = labkit.app.layout.section("previewOptions", "Preview", {labkit.app.layout.field("maxPreviewChannels", Label="Max channels", Kind="numeric", Bind="project.parameters.maxPreviewChannels"), labkit.app.layout.button("refreshPreviewWindow", "Refresh preview", @rhs_preview.analysisRun.refreshPreview)});
end
