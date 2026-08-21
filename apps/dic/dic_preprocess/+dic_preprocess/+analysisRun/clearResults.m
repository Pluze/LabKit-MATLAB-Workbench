% App-owned implementation for dic_preprocess.analysisRun.clearResults within the dic_preprocess product workflow.
function applicationState = clearResults(applicationState)
%CLEARRESULTS Invalidate recorded output paths after a semantic edit.
applicationState.project.results.currentImagesOutputPath = "";
applicationState.project.results.maskOutputPath = "";
end
