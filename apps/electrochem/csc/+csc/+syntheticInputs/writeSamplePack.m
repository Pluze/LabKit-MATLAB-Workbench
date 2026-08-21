% Expected caller: CSC synthetic-input generation and unit tests. Input is a
% LabKit debug context. Output is a deterministic synthetic CV/CT DTA sample
% pack. Side effects: writes anonymous debug input files and records a session
% synthetic-input manifest.
function pack = writeSamplePack(sampleContext)
%WRITESAMPLEPACK Write CSC debug CV/CT DTA files.
    arguments
        sampleContext (1, 1) labkit.app.synthetic.Context
    end

    cvPath = sampleContext.samplePath("csc/representative.DTA");
    zeroScanPath = sampleContext.samplePath("csc/zero_scan_rate.DTA");
    malformedPath = sampleContext.samplePath("csc/malformed.DTA");
    writeTextFile(cvPath, cvctText());
    writeTextFile(zeroScanPath, cvctText(struct("ScanRateMv", 0)));
    writeTextFile(malformedPath, malformedCvctText());

    project = csc.initialData();
    project.inputs.sources = sampleContext.sourceRecord( ...
        "dta1", "cvct", cvPath, true);
    pack = labkit.app.synthetic.Pack( ...
        Scenario="representative-cvct", InitialInput=project, ...
        Artifacts={ ...
            sampleContext.artifact("representative", "cvct", cvPath), ...
            sampleContext.artifact("zeroScanRate", "boundaryInput", zeroScanPath), ...
            sampleContext.artifact("malformed", "boundaryInput", ...
                malformedPath, Expectation="rejects")});
end

function text = cvctText(opts)
    if nargin < 1
        opts = struct();
    end
    scanRateMv = 200;
    if isfield(opts, 'ScanRateMv')
        scanRateMv = opts.ScanRateMv;
    end
    t = linspace(0, 8, 401).';
    vf = -0.8 + 1.6 .* abs(mod(t ./ 4, 2) - 1);
    im = 0.00035 .* vf + 0.00018 .* sin(2 .* pi .* t ./ 4);
    rowsA = curveRows(t, vf, im);
    rowsB = curveRows(t, vf, 0.00032 .* vf + 0.00015 .* cos(2 .* pi .* t ./ 4));
    scanRateLine = "SCANRATE" + tab() + "QUANT" + tab() + sprintf("%.6E", scanRateMv) + tab() + "Scan Rate (mV/s)";
    lines = [
        "EXPLAIN"
        "TAG" + tab() + "TEXT" + tab() + "DEVICE"
        scanRateLine
        "CURVE1" + tab() + "TABLE"
        "Pt" + tab() + "T" + tab() + "Vf" + tab() + "Im" + tab() + "Vu" + tab() + "Sig" + tab() + "Ach" + tab() + "Temp"
        "#" + tab() + "s" + tab() + "V vs. Ref." + tab() + "A" + tab() + "V" + tab() + "V" + tab() + "#" + tab() + "deg C"
        rowsA
        "CURVE2" + tab() + "TABLE"
        "Pt" + tab() + "T" + tab() + "Vf" + tab() + "Im" + tab() + "Vu" + tab() + "Sig" + tab() + "Ach" + tab() + "Temp"
        "#" + tab() + "s" + tab() + "V vs. Ref." + tab() + "A" + tab() + "V" + tab() + "V" + tab() + "#" + tab() + "deg C"
        rowsB
        ];
    text = join(lines, newline) + newline;
end

function text = malformedCvctText()
    lines = [
        "EXPLAIN"
        "TAG" + tab() + "TEXT" + tab() + "DEVICE"
        "SCANRATE" + tab() + "QUANT" + tab() + "2.000000E+002" + tab() + "Scan Rate (mV/s)"
        "This file intentionally omits CURVE TABLE sections."
        ];
    text = join(lines, newline) + newline;
end

function rows = curveRows(t, vf, im)
    rows = strings(numel(t), 1);
    for k = 1:numel(t)
        vu = vf(k) + 0.003 .* sin(2 .* pi .* 0.25 .* t(k));
        sig = 0.00005 .* sin(2 .* pi .* 2 .* t(k));
        temp = 25.0 + 0.02 .* t(k);
        rows(k) = sprintf("%d\t%.6E\t%.6E\t%.6E\t%.6E\t%.6E\t%d\t%.6E", ...
            k - 1, t(k), vf(k), im(k), vu, sig, 0, temp);
    end
end

function writeTextFile(filepath, text)
    fid = fopen(char(filepath), "w", "n", "UTF-8");
    if fid < 0
        error("csc:syntheticInputs:SampleWriteFailed", "Could not write synthetic input file: %s.", filepath);
    end
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", char(text));
end

function value = tab()
    value = char(9);
end
