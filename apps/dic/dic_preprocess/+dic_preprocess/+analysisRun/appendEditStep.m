% App-owned implementation for dic_preprocess.analysisRun.appendEditStep within the dic_preprocess product workflow.
function project = appendEditStep( ...
        project, kind, transform, rectangle, description)
%APPENDEDITSTEP Append one durable registration or crop operation.
step = struct("kind", string(kind), "transform", transform, ...
    "rect", rectangle, "description", string(description));
if isempty(project.annotations.editSteps)
    project.annotations.editSteps = step;
else
    project.annotations.editSteps(end + 1) = step;
end
end
