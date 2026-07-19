% Expected caller: EIS debug launch and unit tests. Input is a
% LabKit debug context. Output is a deterministic synthetic EIS DTA sample
% pack. Side effects: writes anonymous debug input files and records a session
% manifest when available.
function pack = writeSamplePack(debugLog)
%WRITESAMPLEPACK Write EIS debug ZCURVE DTA files.

    folders = debugFolders(debugLog, "eis");
    dtaFolder = fullfile(char(folders.sampleFolder), "dta");
    ensureFolder(dtaFolder);

    eisPath = string(fullfile(dtaFolder, "eis_zcurve_debug.DTA"));
    sparsePath = string(fullfile(dtaFolder, "eis_zcurve_sparse_valid_debug.DTA"));
    malformedPath = string(fullfile(dtaFolder, "eis_malformed_missing_zcurve_debug.DTA"));
    writeTextFile(eisPath, eisText());
    writeTextFile(sparsePath, eisText(struct("Sparse", true)));
    writeTextFile(malformedPath, malformedEisText());

    pack = struct( ...
        "sampleFolder", folders.sampleFolder, ...
        "outputFolder", folders.outputFolder, ...
        "representativeFiles", eisPath, ...
        "boundaryFiles", struct("validEdge", sparsePath, "malformed", malformedPath));
    manifest = struct( ...
        "type", "labkit.debug.samplePack.v1", ...
        "app", "labkit_EIS_app", ...
        "description", "Anonymous ZCURVE DTA boundary pack for EIS debug launch.", ...
        "inputs", struct( ...
            "representativeEisDta", eisPath, ...
            "validEdgeEisDta", sparsePath, ...
            "malformedEisDta", malformedPath), ...
        "outputFolder", folders.outputFolder);
    pack.manifest = manifest;
    recordManifest(debugLog, manifest);
end

function text = eisText(opts)
    if nargin < 1
        opts = struct();
    end
    sparse = isfield(opts, 'Sparse') && opts.Sparse;
    if sparse
        freq = logspace(3, 1, 8).';
    else
        freq = logspace(5, -1, 81).';
    end
    r0 = 85;
    rct = 420;
    tau = 0.045;
    omegaTau = 2 .* pi .* freq .* tau;
    zReal = r0 + rct ./ (1 + omegaTau .^ 2);
    zImag = -rct .* omegaTau ./ (1 + omegaTau .^ 2);
    zMod = hypot(zReal, zImag);
    zPhz = atan2d(zImag, zReal);
    time = (0:numel(freq) - 1).';
    rows = strings(numel(freq), 1);
    for k = 1:numel(freq)
        rows(k) = sprintf("%d\t%.6E\t%.6E\t%.6E\t%.6E\t%.6E\t%.6E\t%.6E\t%.6E", ...
            k - 1, time(k), freq(k), zReal(k), zImag(k), zMod(k), zPhz(k), 1e-6, 0.5);
    end
    lines = [
        "EXPLAIN"
        "TAG" + tab() + "TEXT" + tab() + "DEVICE"
        "TITLE" + tab() + "TEXT" + tab() + "Debug potentiostatic EIS"
        "AREA" + tab() + "QUANT" + tab() + "1.000000E+000" + tab() + "Area (cm^2)"
        "ZCURVE" + tab() + "TABLE" + tab() + "Debug ZCURVE"
        "Pt" + tab() + "Time" + tab() + "Freq" + tab() + "Zreal" + tab() + "Zimag" + tab() + "Zmod" + tab() + "Zphz" + tab() + "Idc" + tab() + "Vdc"
        "#" + tab() + "s" + tab() + "Hz" + tab() + "ohm" + tab() + "ohm" + tab() + "ohm" + tab() + "deg" + tab() + "A" + tab() + "V"
        rows
        ];
    text = join(lines, newline) + newline;
end

function text = malformedEisText()
    lines = [
        "EXPLAIN"
        "TAG" + tab() + "TEXT" + tab() + "DEVICE"
        "TITLE" + tab() + "TEXT" + tab() + "Malformed EIS missing ZCURVE"
        "This file intentionally omits numeric EIS TABLE sections."
        ];
    text = join(lines, newline) + newline;
end

function folders = debugFolders(debugLog, appToken)
    sampleFolder = ""; outputFolder = "";
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
    ensureFolder(sampleFolder); ensureFolder(outputFolder);
    folders = struct("sampleFolder", sampleFolder, "outputFolder", outputFolder);
end

function recordManifest(debugLog, manifest)
    if isstruct(debugLog) && isfield(debugLog, "recordArtifacts") && isa(debugLog.recordArtifacts, "function_handle")
        debugLog.recordArtifacts(manifest);
    end
end

function writeTextFile(filepath, text)
    fid = fopen(char(filepath), "w", "n", "UTF-8");
    if fid < 0
        error("eis:debug:SampleWriteFailed", "Could not write debug sample file: %s.", filepath);
    end
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", char(text));
end

function ensureFolder(folder)
    if exist(char(folder), "dir") ~= 7
        mkdir(char(folder));
    end
end

function value = tab()
    value = char(9);
end
