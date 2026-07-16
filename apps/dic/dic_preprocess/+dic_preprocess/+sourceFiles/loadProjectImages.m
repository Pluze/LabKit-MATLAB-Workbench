% Expected caller: dic_preprocess.appLifecycle.createSession. Input is the
% validated portable source-record array. Outputs are decoded reference and
% moving images; missing optional records produce empty arrays.
function [referenceImage, movingImage] = loadProjectImages(sources)
    referenceImage = readSource(sources, "referenceImage");
    movingImage = readSource(sources, "movingImage");
end

function imageData = readSource(sources, id)
    imageData = [];
    filepath = dic_preprocess.sourceFiles.pathForId(sources, id);
    if strlength(filepath) > 0 && isfile(filepath)
        imageData = imread(filepath);
    end
end
