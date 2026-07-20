% App-owned implementation for gait_analysis.sourceFiles.present within the gait_analysis product workflow.
function view = present(sources, selection, filepath, pose)
%PRESENT Describe the selected pose source and decoded summary.
if isempty(sources)
    selection = labkit.app.event.ListSelection();
end
fileStatus = "No pose file loaded";
if strlength(string(filepath)) > 0
    fileStatus = string(filepath);
end
view = labkit.app.view.Snapshot() ...
    .listSelection("poseFile", selection) ...
    .text("poseFile", fileStatus) ...
    .value("sourceSummary", sourceSummary(pose));
end

function value = sourceSummary(pose)
value = "No pose file loaded";
if pose.ok
    value = string(sprintf( ...
        "%d frames | %d points | %.6g Hz | %s | unit %s", ...
        size(pose.coords, 1), numel(pose.pointNames), ...
        pose.frameRate, pose.sourceFormat, pose.unitName));
end
end
