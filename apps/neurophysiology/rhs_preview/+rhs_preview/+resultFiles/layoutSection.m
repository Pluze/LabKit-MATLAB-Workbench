function section = layoutSection()
section = labkit.app.layout.section("exportSection", "Export", {labkit.app.layout.button("saveProtocol", "Save protocol", @rhs_preview.resultFiles.saveProtocol), labkit.app.layout.button("saveFilterRecord", "Save filter record", @rhs_preview.resultFiles.saveFilterRecord)});
end
