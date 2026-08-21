% Expected caller: Chrono Overlay debug-sample tooling and unit tests.
% Input is a LabKit debug context. Output is a deterministic synthetic DTA
% sample pack. Side effects: writes anonymous debug input files under the
% synthetic inputs folder and writes the synthetic-input manifest.
function pack = writeSamplePack(sampleContext)
%WRITESAMPLEPACK Write Chrono Overlay debug DTA files.
    arguments
        sampleContext (1, 1) labkit.app.synthetic.Context
    end

    currentPath = sampleContext.samplePath("chrono_overlay/current.DTA");
    voltagePath = sampleContext.samplePath("chrono_overlay/voltage.DTA");
    flatPath = sampleContext.samplePath("chrono_overlay/no_pulse.DTA");
    malformedPath = sampleContext.samplePath("chrono_overlay/malformed.DTA");
    writeTextFile(currentPath, chronoText("current"));
    writeTextFile(voltagePath, chronoText("voltage"));
    writeTextFile(flatPath, flatChronoText());
    writeTextFile(malformedPath, malformedChronoText());

    project = chrono_overlay.initialData();
    project.inputs.sources = [ ...
        sampleContext.sourceRecord("dta1", "chrono", currentPath), ...
        sampleContext.sourceRecord("dta2", "chrono", voltagePath)];
    pack = labkit.app.synthetic.Pack( ...
        Scenario="representative-chrono-overlay", InitialInput=project, ...
        Artifacts={ ...
            sampleContext.artifact("currentPulse", "chrono", currentPath), ...
            sampleContext.artifact("voltagePulse", "chrono", voltagePath), ...
            sampleContext.artifact("noPulse", "boundaryInput", flatPath), ...
            sampleContext.artifact("malformed", "boundaryInput", ...
                malformedPath, Expectation="rejects")});
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

function writeTextFile(filepath, text)
    fid = fopen(char(filepath), "w", "n", "UTF-8");
    if fid < 0
        error("chrono_overlay:syntheticInputs:SampleWriteFailed", ...
            "Could not write synthetic input file: %s.", filepath);
    end
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", char(text));
end

function value = tab()
    value = char(9);
end
