% Expected caller: dic_postprocess.actions.table startup action and unit tests.
% Input is a LabKit debug context. Output is a deterministic synthetic Ncorr
% MAT/reference/mask sample pack. Side effects: writes anonymous debug inputs
% and records a session manifest when available.
function pack = writeSamplePack(debugLog)
%WRITESAMPLEPACK Write DIC postprocess debug files.

    folders = debugFolders(debugLog, "dic_postprocess");
    sampleFolder = fullfile(char(folders.sampleFolder), "dic_postprocess");
    ensureFolder(sampleFolder);

    matPath = string(fullfile(sampleFolder, "dic_valid_ncorr_strain_debug.mat"));
    referencePath = string(fullfile(sampleFolder, "dic_reference_debug.png"));
    maskPath = string(fullfile(sampleFolder, "dic_mask_debug.png"));
    edgeMatPath = string(fullfile(sampleFolder, "dic_valid_edge_sparse_roi_debug.mat"));
    malformedMatPath = string(fullfile(sampleFolder, "dic_malformed_missing_strains_debug.mat"));

    [reference, mask, exx, eyy] = syntheticDicPostprocessData(180, 240, false);
    imwrite(reference, char(referencePath));
    imwrite(uint8(255 .* mask), char(maskPath));
    writeNcorrMat(matPath, exx, eyy, mask);

    [~, edgeMask, edgeExx, edgeEyy] = syntheticDicPostprocessData(180, 240, true);
    writeNcorrMat(edgeMatPath, edgeExx, edgeEyy, edgeMask);
    data_dic_save = struct("metadata", struct("note", "malformed synthetic boundary"));
    save(char(malformedMatPath), "data_dic_save");

    manifest = struct( ...
        "type", "labkit.debug.samplePack.v1", ...
        "app", "labkit_DICPostprocess_app", ...
        "description", "Anonymous Ncorr-style DIC strain boundary pack for debug launch.", ...
        "sampleFolder", string(sampleFolder), ...
        "outputFolder", folders.outputFolder, ...
        "representativeFiles", struct("mat", matPath, "reference", referencePath, "mask", maskPath), ...
        "boundaryFiles", struct( ...
            "validEdgeSparseRoiMat", edgeMatPath, ...
            "malformedMissingStrainsMat", malformedMatPath));
    recordManifest(debugLog, manifest);

    pack = manifest;
    pack.matFile = matPath;
    pack.referenceFile = referencePath;
    pack.maskFile = maskPath;
end

function [reference, mask, exx, eyy] = syntheticDicPostprocessData(h, w, sparseRoi)
    [x, y] = meshgrid(1:w, 1:h);
    texture = 0.46 + 0.12 .* sin(x ./ 9) + 0.08 .* cos(y ./ 7) + 0.06 .* sin((x + y) ./ 5);
    reference = uint8(round(255 .* min(1, max(0, texture))));
    if sparseRoi
        mask = ((x - 125).^2 ./ 20^2 + (y - 86).^2 ./ 10^2) <= 1;
    else
        mask = ((x - 120).^2 ./ 76^2 + (y - 92).^2 ./ 44^2) <= 1;
    end
    taper = exp(-(((x - 118) ./ 72).^2 + ((y - 96) ./ 38).^2));
    exx = 0.008 .* taper + 0.0015 .* sin(x ./ 21);
    eyy = -0.005 .* taper + 0.0012 .* cos(y ./ 17);
    exx(~mask) = NaN;
    eyy(~mask) = NaN;
end

function writeNcorrMat(filepath, exx, eyy, mask)
    data_dic_save = struct();
    data_dic_save.strains = struct( ...
        "plot_exx_ref_formatted", exx, ...
        "plot_eyy_ref_formatted", eyy, ...
        "roi_ref_formatted", struct("mask", mask));
    save(char(filepath), "data_dic_save");
end

function folders = debugFolders(debugLog, appToken)
    sampleFolder = "";
    outputFolder = "";
    if isstruct(debugLog)
        if isfield(debugLog, "sampleFolder"), sampleFolder = string(debugLog.sampleFolder); end
        if isfield(debugLog, "outputFolder"), outputFolder = string(debugLog.outputFolder); end
    end
    if strlength(sampleFolder) == 0
        sampleFolder = string(fullfile(tempdir, "LabKit-MATLAB-Workbench", "debug", appToken, "samples"));
    end
    if strlength(outputFolder) == 0
        outputFolder = string(fullfile(tempdir, "LabKit-MATLAB-Workbench", "debug", appToken, "outputs"));
    end
    ensureFolder(sampleFolder);
    ensureFolder(outputFolder);
    folders = struct("sampleFolder", sampleFolder, "outputFolder", outputFolder);
end

function recordManifest(debugLog, manifest)
    if isstruct(debugLog) && isfield(debugLog, "recordArtifacts") && isa(debugLog.recordArtifacts, "function_handle")
        debugLog.recordArtifacts(manifest);
    end
end

function ensureFolder(folder)
    if exist(char(folder), "dir") ~= 7
        mkdir(char(folder));
    end
end
