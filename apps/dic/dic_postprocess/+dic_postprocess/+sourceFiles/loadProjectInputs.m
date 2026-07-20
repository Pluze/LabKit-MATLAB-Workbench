% Expected caller: dic_postprocess.createSession. Inputs are resolved paths
% by semantic role and whether saved results require strain reload.
% Output is rebuildable decoded cache data; missing records stay empty.
function cache = loadProjectInputs(paths, loadStrain)
    cache = struct( ...
        "strain", struct(), ...
        "referenceImage", readImage(paths.referenceImage), ...
        "maskImage", readImage(paths.maskImage), ...
        "overlayExx", [], ...
        "overlayEyy", []);
    filepath = string(paths.dicMat);
    if loadStrain && strlength(filepath) > 0 && isfile(filepath)
        cache.strain = dic_postprocess.sourceFiles.loadNcorrStrain(filepath);
    end
end

function imageData = readImage(filepath)
    imageData = [];
    filepath = string(filepath);
    if strlength(filepath) > 0 && isfile(filepath)
        imageData = imread(filepath);
    end
end
