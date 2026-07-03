% Expected caller: chrono_overlay.definitionActions startup action and unit tests.
% Input is a LabKit debug context. Output is a deterministic synthetic DTA
% sample pack. Side effects: writes anonymous debug input files under the
% debug samples folder and records a session manifest when available.
function pack = writeSamplePack(debugLog)
%WRITESAMPLEPACK Write Chrono Overlay debug DTA files.

    folders = debugFolders(debugLog, "chrono_overlay");
    dtaFolder = fullfile(char(folders.sampleFolder), "dta");
    ensureFolder(dtaFolder);

    currentPath = string(fullfile(dtaFolder, "chrono_current_pulse_debug.DTA"));
    voltagePath = string(fullfile(dtaFolder, "chrono_voltage_pulse_debug.DTA"));
    flatPath = string(fullfile(dtaFolder, "chrono_valid_no_pulse_debug.DTA"));
    malformedPath = string(fullfile(dtaFolder, "chrono_malformed_missing_table_debug.DTA"));
    writeTextFile(currentPath, chronoText("current"));
    writeTextFile(voltagePath, chronoText("voltage"));
    writeTextFile(flatPath, flatChronoText());
    writeTextFile(malformedPath, malformedChronoText());

    pack = struct( ...
        "sampleFolder", folders.sampleFolder, ...
        "outputFolder", folders.outputFolder, ...
        "representativeFiles", [currentPath; voltagePath], ...
        "boundaryFiles", struct( ...
            "validEdge", flatPath, ...
            "malformed", malformedPath));
    manifest = struct( ...
        "type", "labkit.debug.samplePack.v1", ...
        "app", "labkit_ChronoOverlay_app", ...
        "description", "Anonymous chrono DTA boundary pack for overlay debug launch.", ...
        "inputs", struct( ...
            "representativeChronoDta", pack.representativeFiles, ...
            "validEdgeChronoDta", flatPath, ...
            "malformedChronoDta", malformedPath), ...
        "outputFolder", folders.outputFolder);
    pack.manifest = manifest;
    recordManifest(debugLog, manifest);
end

function text = flatChronoText()
    t = (0:0.002:0.12).';
    vf = 0.015 .* sin(2 .* pi .* 6 .* t);
    im = 4e-6 .* sin(2 .* pi .* 15 .* t);
    rows = strings(numel(t), 1);
    for k = 1:numel(t)
        rows(k) = sprintf("%d\t%.6E\t%.6E\t%.6E\t%.6E\t%.6E\t%d\t%.6E", ...
            k - 1, t(k), vf(k), im(k), vf(k) .* 0.98, 0, 0, 25.0);
    end
    lines = [
        "EXPLAIN"
        "TAG" + tab() + "TEXT" + tab() + "DEVICE"
        "AREA" + tab() + "QUANT" + tab() + "1.000000E+000" + tab() + "Area (cm^2)"
        "SAMPLETIME" + tab() + "QUANT" + tab() + "2.000000E-003" + tab() + "Sample Time (s)"
        "Curve" + tab() + "TABLE" + tab() + "Valid chrono without clear pulse"
        "Pt" + tab() + "T" + tab() + "Vf" + tab() + "Im" + tab() + "Vu" + tab() + "Sig" + tab() + "Ach" + tab() + "Temp"
        "#" + tab() + "s" + tab() + "V vs. Ref." + tab() + "A" + tab() + "V" + tab() + "V" + tab() + "#" + tab() + "deg C"
        rows
        ];
    text = join(lines, newline) + newline;
end

function text = malformedChronoText()
    lines = [
        "EXPLAIN"
        "TAG" + tab() + "TEXT" + tab() + "DEVICE"
        "SAMPLETIME" + tab() + "QUANT" + tab() + "2.000000E-003"
        "This file intentionally omits a numeric TABLE section."
        ];
    text = join(lines, newline) + newline;
end

function text = chronoText(mode)
    lines = [
        "EXPLAIN"
        "TAG" + tab() + "TEXT" + tab() + "DEVICE"
        "AREA" + tab() + "QUANT" + tab() + "1.000000E+000" + tab() + "Area (cm^2)"
        "SAMPLETIME" + tab() + "QUANT" + tab() + "2.000000E-003" + tab() + "Sample Time (s)"
        stepLines(mode)
        "Curve" + tab() + "TABLE" + tab() + "Debug chrono curve"
        "Pt" + tab() + "T" + tab() + "Vf" + tab() + "Im" + tab() + "Vu" + tab() + "Sig" + tab() + "Ach" + tab() + "Temp"
        "#" + tab() + "s" + tab() + "V vs. Ref." + tab() + "A" + tab() + "V" + tab() + "V" + tab() + "#" + tab() + "deg C"
        chronoRows(mode)
        ];
    text = join(lines, newline) + newline;
end

function lines = stepLines(mode)
    durations = [0.02 0.04 0.03 0.02 0.04 0.03];
    if mode == "current"
        values = [0 -0.0025 0 0 0.0020 0];
        prefix = "ISTEP";
    else
        values = [0 -0.7 0 0 0.65 0];
        prefix = "VSTEP";
    end
    lines = strings(numel(durations) * 2, 1);
    for k = 1:numel(durations)
        lines(2 * k - 1) = prefix + k + tab() + "QUANT" + tab() + sprintf("%.6E", values(k));
        lines(2 * k) = "TSTEP" + k + tab() + "QUANT" + tab() + sprintf("%.6E", durations(k));
    end
end

function rows = chronoRows(mode)
    t = (0:0.0005:0.18).';
    cath = t >= 0.020 & t <= 0.060;
    anod = t >= 0.110 & t <= 0.150;
    if mode == "current"
        im = 6e-5 .* sin(2 .* pi .* 35 .* t);
        im(cath) = -0.0025 + 8e-5 .* sin(2 .* pi .* 60 .* t(cath));
        im(anod) = 0.0020 + 7e-5 .* sin(2 .* pi .* 55 .* t(anod));
        vf = 0.03 .* sin(2 .* pi .* 12 .* t);
        vf(cath) = -0.45 - 0.18 .* (1 - exp(-(t(cath) - 0.020) ./ 0.010));
        vf(anod) = 0.38 + 0.16 .* (1 - exp(-(t(anod) - 0.110) ./ 0.012));
    else
        vf = 0.02 .* sin(2 .* pi .* 8 .* t);
        vf(cath) = -0.7;
        vf(anod) = 0.65;
        im = 1e-5 .* sin(2 .* pi .* 30 .* t);
        im(cath) = -0.0018 .* exp(-(t(cath) - 0.020) ./ 0.018);
        im(anod) = 0.0015 .* exp(-(t(anod) - 0.110) ./ 0.020);
    end
    rows = strings(numel(t), 1);
    for k = 1:numel(t)
        vu = vf(k) + 0.006 .* sin(2 .* pi .* 4 .* t(k));
        sig = 0.0002 .* sin(2 .* pi .* 2 .* t(k));
        temp = 25.0 + 0.08 .* t(k) + 0.02 .* sin(2 .* pi .* 0.5 .* t(k));
        rows(k) = sprintf("%d\t%.6E\t%.6E\t%.6E\t%.6E\t%.6E\t%d\t%.6E", ...
            k - 1, t(k), vf(k), im(k), vu, sig, 0, temp);
    end
end

function folders = debugFolders(debugLog, appToken)
    sampleFolder = "";
    outputFolder = "";
    if isstruct(debugLog)
        if isfield(debugLog, "sampleFolder")
            sampleFolder = string(debugLog.sampleFolder);
        end
        if isfield(debugLog, "outputFolder")
            outputFolder = string(debugLog.outputFolder);
        end
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
    if isstruct(debugLog) && isfield(debugLog, "recordArtifacts") && ...
            isa(debugLog.recordArtifacts, "function_handle")
        debugLog.recordArtifacts(manifest);
    end
end

function writeTextFile(filepath, text)
    fid = fopen(char(filepath), "w", "n", "UTF-8");
    if fid < 0
        error("chrono_overlay:debug:SampleWriteFailed", ...
            "Could not write debug sample file: %s.", filepath);
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
