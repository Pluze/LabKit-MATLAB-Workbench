% App-owned implementation for dic_preprocess.analysisRun.startPointMatching within the dic_preprocess product workflow.
function state = startPointMatching(state, ~)
if dic_preprocess.sourceFiles.hasImagePair(state.session.cache)
    state.session.workflow.mode = "matching";
    state.project.annotations.matchReferencePoints = zeros(0,2);
    state.project.annotations.matchMovingPoints = zeros(0,2);
end
end
