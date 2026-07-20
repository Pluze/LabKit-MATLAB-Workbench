% App-owned implementation for gait_analysis.stepPreview.boundedIndex within the gait_analysis product workflow.
function index = boundedIndex(applicationState, requested)
%BOUNDEDINDEX Clamp one requested step row to available results.
count = height(applicationState.project.results.analysis.stepTable);
if count == 0
    index = 1;
else
    index = min(max(1, round(double(requested))), count);
end
end
