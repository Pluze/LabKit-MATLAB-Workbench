function section = layoutSection()
section = labkit.app.layout.section("sourceSection", "RHS sources", {labkit.app.layout.fileList("rhsFile", Label="RHS file", Filters=["*.rhs", "Intan RHS"], SelectionMode="single", MaxFiles=1, Bind="project.inputs.sources", SourceRole="recording", SourceIdPrefix="recording", Required=true), labkit.app.layout.fileList("protocolFile", Label="Protocol JSON", Filters=["*.json", "Protocol JSON"], SelectionMode="single", MaxFiles=1, Bind="project.inputs.sources", SourceRole="protocol", SourceIdPrefix="protocol", Required=false)});
end
