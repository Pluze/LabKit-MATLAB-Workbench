% App-owned implementation for video_marker.resultFiles.exportMarkers within the video_marker product workflow.
function state = exportMarkers(state, context)
%EXPORTMARKERS Write the self-describing marker CSV.
if isempty(state.session.cache.currentImage)
    context.alert("Open a video before exporting marker CSV.", "No video");
    return
end
paths = labkit.app.source.paths(state.project.inputs.sources);
startPath = video_marker.resultFiles.defaultOutputPath( ...
    paths(1), "video_marker_markers.csv");
choice = context.chooseOutputFile( ...
    ["*.csv", "Marker CSV files"], startPath);
if choice.Cancelled
    context.log("info", ...
        "video_marker.resultfiles.exportmarkers.cancelled", ...
        "Marker export cancelled.");
    return
end
filepath = string(choice.Value);
try
    video_marker.markerCsv.writeFile(filepath, ...
        state.project.annotations.frames, ...
        state.project.annotations.skeleton, ...
        state.session.cache.videoInfo, ...
        state.project.annotations.calibration);
catch cause
    context.log("error", "video_marker.resultfiles.exportmarkers.exception", "Could not export marker CSV", ...
        Category="failure", Audience="developer", Exception=cause);
    context.alert(cause.message, "Could not export marker CSV");
    return
end
state.project.results.markerOutputPath = filepath;
context.log("info", "video_marker.resultfiles.exportmarkers.completed", ...
    "Exported the marker CSV.");
end
