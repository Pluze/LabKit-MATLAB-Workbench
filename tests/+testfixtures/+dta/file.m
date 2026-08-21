function filepath = file(filename)
%FILE Create and return a cross-owner DTA fixture path.

    root = fullfile(tempdir, "labkit_synthetic_dta_fixtures");
    if exist(root, "dir") ~= 7
        mkdir(root);
    end

    filepath = fullfile(root, char(filename));
    text = fixtureText(string(filename));
    writeTextFile(filepath, text);
end

function text = fixtureText(filename)
    switch filename
        case {"chrono_chronopot_current_pulse_0p2ms.DTA", ...
                "chrono_chronopot_current_pulse_1ms.DTA", ...
                "chrono_chronopot_current_pt_0p65ms.DTA"}
            text = chronoText("current");
        case {"chrono_chronoamp_voltage_pulse_0p2ms.DTA", ...
                "chrono_chronoamp_voltage_pulse_1ms.DTA"}
            text = chronoText("voltage");
        case {"cv_cyclic_voltammetry_pt_reference.DTA", ...
                "cv_cyclic_voltammetry_pt_replicate.DTA"}
            text = cvctText();
        case "cv_cyclic_voltammetry_1cycle.DTA"
            text = cvctCycleCountText(1);
        case "cv_cyclic_voltammetry_2cycle.DTA"
            text = cvctCycleCountText(2);
        case "cv_cyclic_voltammetry_3cycle.DTA"
            text = cvctCycleCountText(3);
        case "cv_cyclic_voltammetry_4cycle.DTA"
            text = cvctCycleCountText(4);
        case "eis_potentiostatic_zcurve.DTA"
            text = eisText();
        otherwise
            error("LabKit:Tests:UnknownDtaFixture", ...
                "Unknown synthetic DTA fixture: %s", filename);
    end
end

function text = chronoText(mode)
    lines = [
        "EXPLAIN"
        "AREA" + tab + "QUANT" + tab + "1.000000E+000" + tab + "Area (cm^2)"
        "SAMPLETIME" + tab + "QUANT" + tab + "2.500000E-001" + tab + "Sample Time (s)"
        stepLines(mode)
        "Curve" + tab + "TABLE" + tab + "Synthetic chrono curve"
        "Pt" + tab + "T" + tab + "Vf" + tab + "Im"
        "#" + tab + "s" + tab + "V" + tab + "A"
        chronoRows()
        ];
    text = join(lines, newline) + newline;
end

function lines = stepLines(mode)
    durations = [1 1 1 1 1 1];
    if mode == "current"
        values = [0 -0.01 0 0 0.01 0];
        prefix = "ISTEP";
    else
        values = [0 -1.5 0 0 1.5 0];
        prefix = "VSTEP";
    end

    lines = strings(12, 1);
    out = 0;
    for k = 1:numel(durations)
        out = out + 1;
        lines(out) = prefix + k + tab + "QUANT" + tab + sprintf("%.6E", values(k));
        out = out + 1;
        lines(out) = "TSTEP" + k + tab + "QUANT" + tab + sprintf("%.6E", durations(k));
    end
end

function rows = chronoRows()
    t = (0:0.25:6).';
    im = zeros(size(t));
    vf = zeros(size(t));
    im(t >= 1 & t <= 2) = -0.01;
    im(t >= 4 & t <= 5) = 0.01;
    vf(t >= 1 & t <= 2) = -1.0;
    vf(t >= 4 & t <= 5) = 1.0;
    vf(t == 3) = -0.1;

    rows = strings(numel(t), 1);
    for k = 1:numel(t)
        rows(k) = sprintf("%d\t%.6E\t%.6E\t%.6E", k - 1, t(k), vf(k), im(k));
    end
end

function text = cvctText()
    lines = [
        "EXPLAIN"
        "SCANRATE" + tab + "QUANT" + tab + "2.000000E+002" + tab + "Scan Rate (mV/s)"
        "CURVE1" + tab + "TABLE"
        "Pt" + tab + "T" + tab + "Vf" + tab + "Im"
        "#" + tab + "s" + tab + "V" + tab + "A"
        "0" + tab + "0.000000E+000" + tab + "-1.000000E+000" + tab + "-1.000000E-003"
        "1" + tab + "1.000000E+000" + tab + "0.000000E+000" + tab + "1.000000E-003"
        "2" + tab + "2.000000E+000" + tab + "1.000000E+000" + tab + "1.000000E-003"
        "CURVE2" + tab + "TABLE"
        "Pt" + tab + "T" + tab + "Vf" + tab + "Im"
        "0" + tab + "0.000000E+000" + tab + "1.000000E-001" + tab + "3.000000E-006"
        "1" + tab + "1.000000E+000" + tab + "2.000000E-001" + tab + "4.000000E-006"
        ];
    text = join(lines, newline) + newline;
end

function text = cvctCycleCountText(count)
    cycleBlocks = cell(count, 1);
    for k = 1:count
        cycleBlocks{k} = cvctCycleLines(k);
    end
    lines = [
        "EXPLAIN"
        "SCANRATE" + tab + "QUANT" + tab + "1.000000E+002" + tab + "Scan Rate (mV/s)"
        vertcat(cycleBlocks{:})
        ];
    text = join(lines, newline) + newline;
end

function lines = cvctCycleLines(index)
    scale = 1 + 0.1 * (index - 1);
    lines = [
        "CURVE" + index + tab + "TABLE"
        "Pt" + tab + "T" + tab + "Vf" + tab + "Im"
        "#" + tab + "s" + tab + "V" + tab + "A"
        "0" + tab + "0.000000E+000" + tab + "-5.000000E-001" + tab + sprintf("%.6E", -1.0e-3 * scale)
        "1" + tab + "1.000000E+000" + tab + "0.000000E+000" + tab + sprintf("%.6E", 1.0e-3 * scale)
        "2" + tab + "2.000000E+000" + tab + "5.000000E-001" + tab + sprintf("%.6E", 1.0e-3 * scale)
        ];
end

function text = eisText()
    lines = [
        "EXPLAIN"
        "TAG" + tab + "TEXT" + tab
        "TITLE" + tab + "TEXT" + tab + "Potentiostatic EIS"
        "AREA" + tab + "QUANT" + tab + "1.760000E+000" + tab + "Area (cm^2)"
        "ZCURVE" + tab + "TABLE"
        "Pt" + tab + "Time" + tab + "Freq" + tab + "Zreal" + tab + "Zimag" + tab + "Zmod" + tab + "Zphz" + tab + "Idc" + tab + "Vdc"
        "#" + tab + "s" + tab + "Hz" + tab + "ohm" + tab + "ohm" + tab + "ohm" + tab + "deg" + tab + "A" + tab + "V"
        "0" + tab + "0.000000E+000" + tab + "9.990410E-001" + tab + "1.387798E+002" + tab + "-2.786225E+000" + tab + "1.388078E+002" + tab + "-1.149700E+000" + tab + "1.000000E-006" + tab + "5.000000E-001"
        "1" + tab + "1.000000E+000" + tab + "1.000000E+001" + tab + "1.100000E+002" + tab + "-4.000000E+000" + tab + "1.100727E+002" + tab + "-2.081000E+000" + tab + "1.000000E-006" + tab + "5.000000E-001"
        "2" + tab + "2.000000E+000" + tab + "1.000000E+002" + tab + "9.000000E+001" + tab + "-8.000000E+000" + tab + "9.035485E+001" + tab + "-5.079600E+000" + tab + "1.000000E-006" + tab + "5.000000E-001"
        ];
    text = join(lines, newline) + newline;
end

function writeTextFile(filepath, text)
    fid = fopen(filepath, "w", "n", "UTF-8");
    assert(fid > 0, "Unable to create synthetic DTA fixture: %s", filepath);
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", text);
    clear cleanup
end

function value = tab()
    value = char(9);
end
