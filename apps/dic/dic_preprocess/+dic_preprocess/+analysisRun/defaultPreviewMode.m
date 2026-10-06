function value = defaultPreviewMode(applicationState)
%DEFAULTPREVIEWMODE Choose the useful preview for available source images.
if dic_preprocess.sourceFiles.hasImagePair(applicationState.session.cache)
    value = "False-color overlay";
else
    value = "Current pair";
end
end
