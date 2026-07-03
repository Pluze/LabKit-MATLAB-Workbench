% Expected caller: vt_resistance.actions.table startup action and unit tests.
% Input is a LabKit debug context. Output is a deterministic synthetic chrono
% DTA sample pack. Side effects: writes anonymous debug input files and records
% a session manifest when available.
function pack = writeSamplePack(debugLog)
%WRITESAMPLEPACK Write VT resistance debug chrono DTA files.

    folders = debugFolders(debugLog, "vt_resistance");
    dtaFolder = fullfile(char(folders.sampleFolder), "dta");
    ensureFolder(dtaFolder);

    currentPath = string(fullfile(dtaFolder, "chrono_vt_current_debug.DTA"));
    weakPath = string(fullfile(dtaFolder, "chrono_vt_valid_low_resistance_debug.DTA"));
    malformedPath = string(fullfile(dtaFolder, "chrono_vt_malformed_missing_table_debug.DTA"));
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
        "app", "labkit_VTResistance_app", ...
        "description", "Anonymous chrono DTA boundary pack for resistance debug launch.", ...
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
        "Curve" + tab() + "TABLE" + tab() + "Valid low-resistance chrono curve"
        "Pt" + tab() + "T" + tab() + "Vf" + tab() + "Im" + tab() + "Vu" + tab() + "Sig" + tab() + "Ach" + tab() + "Temp"
        "#" + tab() + "s" + tab() + "V vs. Ref." + tab() + "A" + tab() + "V" + tab() + "V" + tab() + "#" + tab() + "deg C"
        weakRows()
        ];
    text = join(lines, newline) + newline;
end

function rows = weakRows()
    t = (0:0.001:0.21).';
    cath = t >= 0.020 & t <= 0.080;
    anod = t >= 0.125 & t <= 0.185;
    im = zeros(size(t));
    im(cath) = -0.002;
    im(anod) = 0.0018;
    vf = 0.002 .* sin(2 .* pi .* 8 .* t);
    vf(cath) = -0.006;
    vf(anod) = 0.005;
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
        "ISTEP1" + tab() + "QUANT" + tab() + "-2.000000E-003"
        "TSTEP1" + tab() + "QUANT" + tab() + "6.000000E-002"
        "This malformed resistance sample omits the numeric TABLE."
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
        "Curve" + tab() + "TABLE" + tab() + "Debug resistance chrono curve"
        "Pt" + tab() + "T" + tab() + "Vf" + tab() + "Im" + tab() + "Vu" + tab() + "Sig" + tab() + "Ach" + tab() + "Temp"
        "#" + tab() + "s" + tab() + "V vs. Ref." + tab() + "A" + tab() + "V" + tab() + "V" + tab() + "#" + tab() + "deg C"
        chronoRows()
        ];
    text = join(lines, newline) + newline;
end

function lines = stepLines()
    durations = [0.020 0.060 0.025 0.020 0.060 0.025];
    values = [0 -0.002 0 0 0.0018 0];
    lines = strings(numel(durations) * 2, 1);
    for k = 1:numel(durations)
        lines(2 * k - 1) = "ISTEP" + k + tab() + "QUANT" + tab() + sprintf("%.6E", values(k));
        lines(2 * k) = "TSTEP" + k + tab() + "QUANT" + tab() + sprintf("%.6E", durations(k));
    end
end

function rows = chronoRows()
    t = (0:0.0005:0.21).';
    cath = t >= 0.020 & t <= 0.080;
    anod = t >= 0.125 & t <= 0.185;
    im = 2e-5 .* sin(2 .* pi .* 40 .* t);
    im(cath) = -0.002 + 3e-5 .* sin(2 .* pi .* 60 .* t(cath));
    im(anod) = 0.0018 + 3e-5 .* sin(2 .* pi .* 55 .* t(anod));
    vf = 0.015 .* sin(2 .* pi .* 8 .* t);
    vf(cath) = -0.035 + 170 .* abs(im(cath)) + 0.010 .* exp(-(t(cath) - 0.020) ./ 0.018);
    vf(anod) = 0.030 + 160 .* abs(im(anod)) - 0.008 .* exp(-(t(anod) - 0.125) ./ 0.018);
    rows = strings(numel(t), 1);
    for k = 1:numel(t)
        vu = vf(k) + 0.002 .* sin(2 .* pi .* 4 .* t(k));
        sig = 0.0001 .* sin(2 .* pi .* 2 .* t(k));
        temp = 25.0 + 0.04 .* t(k);
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
        error("vt_resistance:debug:SampleWriteFailed", "Could not write debug sample file: %s.", filepath);
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
