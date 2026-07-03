% Expected caller: cic.actions.table startup action and unit tests. Input is a
% LabKit debug context. Output is a deterministic synthetic chrono DTA sample
% pack. Side effects: writes anonymous debug input files and records a session
% manifest when available.
function pack = writeSamplePack(debugLog)
%WRITESAMPLEPACK Write CIC debug chrono DTA files.

    folders = debugFolders(debugLog, "cic");
    dtaFolder = fullfile(char(folders.sampleFolder), "dta");
    ensureFolder(dtaFolder);

    currentPath = string(fullfile(dtaFolder, "chrono_cic_current_debug.DTA"));
    weakPath = string(fullfile(dtaFolder, "chrono_cic_valid_weak_response_debug.DTA"));
    malformedPath = string(fullfile(dtaFolder, "chrono_cic_malformed_missing_columns_debug.DTA"));
    writeTextFile(currentPath, chronoText());
    writeTextFile(weakPath, weakChronoText());
    writeTextFile(malformedPath, malformedChronoText());

    pack = struct( ...
        "sampleFolder", folders.sampleFolder, ...
        "outputFolder", folders.outputFolder, ...
        "representativeFiles", currentPath, ...
        "boundaryFiles", struct("validEdge", weakPath, "malformed", malformedPath));
    manifest = struct( ...
        "type", "labkit.debug.samplePack.v1", ...
        "app", "labkit_CIC_app", ...
        "description", "Anonymous current-controlled chrono DTA boundary pack for CIC debug launch.", ...
        "inputs", struct( ...
            "representativeChronoDta", currentPath, ...
            "validEdgeChronoDta", weakPath, ...
            "malformedChronoDta", malformedPath), ...
        "outputFolder", folders.outputFolder);
    pack.manifest = manifest;
    recordManifest(debugLog, manifest);
end

function text = weakChronoText()
    lines = [
        "EXPLAIN"
        "TAG" + tab() + "TEXT" + tab() + "DEVICE"
        "AREA" + tab() + "QUANT" + tab() + "1.000000E+000" + tab() + "Area (cm^2)"
        "SAMPLETIME" + tab() + "QUANT" + tab() + "1.000000E-003" + tab() + "Sample Time (s)"
        stepLines()
        "Curve" + tab() + "TABLE" + tab() + "Valid weak-response chrono curve"
        "Pt" + tab() + "T" + tab() + "Vf" + tab() + "Im" + tab() + "Vu" + tab() + "Sig" + tab() + "Ach" + tab() + "Temp"
        "#" + tab() + "s" + tab() + "V vs. Ref." + tab() + "A" + tab() + "V" + tab() + "V" + tab() + "#" + tab() + "deg C"
        weakRows()
        ];
    text = join(lines, newline) + newline;
end

function rows = weakRows()
    t = (0:0.001:0.17).';
    im = 2e-6 .* sin(2 .* pi .* 50 .* t);
    vf = 0.003 .* sin(2 .* pi .* 8 .* t);
    rows = strings(numel(t), 1);
    for k = 1:numel(t)
        rows(k) = sprintf("%d\t%.6E\t%.6E\t%.6E\t%.6E\t%.6E\t%d\t%.6E", ...
            k - 1, t(k), vf(k), im(k), vf(k), 0, 0, 25.0);
    end
end

function text = malformedChronoText()
    lines = [
        "EXPLAIN"
        "TAG" + tab() + "TEXT" + tab() + "DEVICE"
        "Curve" + tab() + "TABLE" + tab() + "Malformed chrono missing Im"
        "Pt" + tab() + "T" + tab() + "Vf"
        "#" + tab() + "s" + tab() + "V"
        "0" + tab() + "0.000000E+000" + tab() + "0.000000E+000"
        ];
    text = join(lines, newline) + newline;
end

function text = chronoText()
    lines = [
        "EXPLAIN"
        "TAG" + tab() + "TEXT" + tab() + "DEVICE"
        "AREA" + tab() + "QUANT" + tab() + "1.000000E+000" + tab() + "Area (cm^2)"
        "SAMPLETIME" + tab() + "QUANT" + tab() + "1.000000E-003" + tab() + "Sample Time (s)"
        stepLines()
        "Curve" + tab() + "TABLE" + tab() + "Debug CIC chrono curve"
        "Pt" + tab() + "T" + tab() + "Vf" + tab() + "Im" + tab() + "Vu" + tab() + "Sig" + tab() + "Ach" + tab() + "Temp"
        "#" + tab() + "s" + tab() + "V vs. Ref." + tab() + "A" + tab() + "V" + tab() + "V" + tab() + "#" + tab() + "deg C"
        chronoRows()
        ];
    text = join(lines, newline) + newline;
end

function lines = stepLines()
    durations = [0.015 0.050 0.020 0.015 0.050 0.020];
    values = [0 -0.003 0 0 0.0025 0];
    lines = strings(numel(durations) * 2, 1);
    for k = 1:numel(durations)
        lines(2 * k - 1) = "ISTEP" + k + tab() + "QUANT" + tab() + sprintf("%.6E", values(k));
        lines(2 * k) = "TSTEP" + k + tab() + "QUANT" + tab() + sprintf("%.6E", durations(k));
    end
end

function rows = chronoRows()
    t = (0:0.0005:0.17).';
    cath = t >= 0.015 & t <= 0.065;
    anod = t >= 0.100 & t <= 0.150;
    im = 4e-5 .* sin(2 .* pi .* 50 .* t);
    im(cath) = -0.003 + 8e-5 .* sin(2 .* pi .* 90 .* t(cath));
    im(anod) = 0.0025 + 7e-5 .* sin(2 .* pi .* 80 .* t(anod));
    vf = 0.02 .* sin(2 .* pi .* 10 .* t);
    vf(cath) = -0.52 - 0.16 .* (1 - exp(-(t(cath) - 0.015) ./ 0.012));
    vf(anod) = 0.42 + 0.14 .* (1 - exp(-(t(anod) - 0.100) ./ 0.014));
    rows = strings(numel(t), 1);
    for k = 1:numel(t)
        vu = vf(k) + 0.004 .* sin(2 .* pi .* 5 .* t(k));
        sig = 0.00015 .* sin(2 .* pi .* 3 .* t(k));
        temp = 25.0 + 0.05 .* t(k);
        rows(k) = sprintf("%d\t%.6E\t%.6E\t%.6E\t%.6E\t%.6E\t%d\t%.6E", ...
            k - 1, t(k), vf(k), im(k), vu, sig, 0, temp);
    end
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
        error("cic:debug:SampleWriteFailed", "Could not write debug sample file: %s.", filepath);
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
