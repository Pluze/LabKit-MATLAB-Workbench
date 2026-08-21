% App-owned implementation for video_marker.resultFiles.clearExportState within the video_marker product workflow.
function state = clearExportState(state)
%CLEAREXPORTSTATE Invalidate recorded output paths after an annotation change.
state.project.results.markerOutputPath = "";
state.project.results.coordinateOutputPath = "";
end
