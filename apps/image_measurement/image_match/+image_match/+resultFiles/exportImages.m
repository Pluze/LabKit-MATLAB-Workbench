function state = exportImages(state, context)
%EXPORTIMAGES Apply the committed match pipeline to each source and write it.
if isempty(state.session.cache.referenceItem) || isempty(state.project.annotations.steps)
    context.alert("Load images and apply a match before export.", "Export unavailable"); return
end
choice = context.chooseOutputFolder(pwd);
if choice.Cancelled, return, end
folder = string(choice.Value);
paths = context.resolveSourcePaths(state.project.inputs.sources);
items = image_match.sourceFiles.readImages(paths);
reference = state.session.cache.referenceItem;
images = image_match.analysisRun.applyPipeline({items.image}, ...
    state.project.annotations.steps, image_match.imagePreview.presentationData.previewImage(reference.image));
for k = 1:numel(items)
    [~, name] = fileparts(paths(k));
    labkit.image.writeFile(images{k}, fullfile(folder, name + ".png"));
end
context.appendStatus("Exported " + string(numel(items)) + " matched image(s).");
end
