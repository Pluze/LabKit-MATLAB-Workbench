% App-owned implementation for batch_crop.sourceFiles.currentIndex within the batch_crop product workflow.
function index = currentIndex(applicationState)
index = max(0, round(double( ...
    applicationState.session.selection.currentIndex)));
end
