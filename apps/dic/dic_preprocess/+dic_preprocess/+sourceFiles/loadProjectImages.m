% Expected caller: dic_preprocess.createSession. Inputs are resolved
% reference and moving paths. Missing paths produce empty arrays.
function [referenceImage, movingImage] = loadProjectImages( ...
        referencePath, movingPath)
    referenceImage = readSource(referencePath);
    movingImage = readSource(movingPath);
end

function imageData = readSource(filepath)
    imageData = [];
    if strlength(filepath) > 0 && isfile(filepath)
        imageData = imread(filepath);
    end
end
