function view = present(state)
%PRESENT Compose feature-owned Response Review Stats view fragments.

model = response_review_stats.analysisRun.presentationModel(state);
view = response_review_stats.analysisRun.present(model) ...
    .include(response_review_stats.resultFiles.present(state, model));
end
