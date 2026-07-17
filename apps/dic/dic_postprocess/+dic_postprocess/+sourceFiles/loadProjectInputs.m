% Expected caller: dic_postprocess.createSession. Inputs are
% resolved source records and whether saved results require strain reload.
% Output is rebuildable decoded cache data; missing records stay empty.
function cache = loadProjectInputs(sources, loadStrain)
    cache = struct( ...
        "strain", struct(), ...
        "referenceImage", readImage(sources, "referenceImage"), ...
        "maskImage", readImage(sources, "maskImage"), ...
        "overlayExx", [], ...
        "overlayEyy", []);
    filepath = labkit.ui.runtime.sourcePaths(sources, "dicMat");
    if loadStrain && strlength(filepath) > 0 && isfile(filepath)
        cache.strain = dic_postprocess.sourceFiles.loadNcorrStrain(filepath);
    end
end

function imageData = readImage(sources, id)
    imageData = [];
    filepath = labkit.ui.runtime.sourcePaths(sources, id);
    if strlength(filepath) > 0 && isfile(filepath)
        imageData = imread(filepath);
    end
end
