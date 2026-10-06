function applicationState = clearResults(applicationState)
%CLEARRESULTS Invalidate recorded output paths after a semantic edit.
applicationState.project.results.currentImagesOutputPath = "";
applicationState.project.results.maskOutputPath = "";
end
