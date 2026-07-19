function view = present(applicationState)
%PRESENT Describe DIC output availability.
cache = applicationState.session.cache;
hasPair = dic_preprocess.sourceFiles.hasImagePair(cache);
hasMask = ~isempty(applicationState.project.annotations.maskImage) || ...
    size(applicationState.project.annotations.maskPoints, 1) >= 3;
view = labkit.app.view.Snapshot() ...
    .enabled("saveCurrentImages", hasPair) ...
    .enabled("saveMask", hasMask);
end
