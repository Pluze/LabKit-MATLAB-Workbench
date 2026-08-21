% Expected caller: EIS synthetic-input generation and unit tests. Input is a
% LabKit debug context. Output is a deterministic synthetic EIS DTA sample
% pack. Side effects: writes anonymous debug input files and records a session
% synthetic-input manifest.
function pack = writeSamplePack(sampleContext)
%WRITESAMPLEPACK Write EIS debug ZCURVE DTA files.
    arguments
        sampleContext (1, 1) labkit.app.synthetic.Context
    end

    eisPath = sampleContext.samplePath("eis/representative.DTA");
    sparsePath = sampleContext.samplePath("eis/sparse.DTA");
    malformedPath = sampleContext.samplePath("eis/malformed.DTA");
    writeTextFile(eisPath, eisText());
    writeTextFile(sparsePath, eisText(struct("Sparse", true)));
    writeTextFile(malformedPath, malformedEisText());

    project = eis.initialData();
    project.inputs.sources = sampleContext.sourceRecord( ...
        "dta1", "eis", eisPath);
    pack = labkit.app.synthetic.Pack( ...
        Scenario="representative-impedance", InitialInput=project, ...
        Artifacts={ ...
            sampleContext.artifact("representative", "eis", eisPath), ...
            sampleContext.artifact("sparse", "boundaryInput", sparsePath), ...
            sampleContext.artifact("malformed", "boundaryInput", ...
                malformedPath, Expectation="rejects")});
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

function writeTextFile(filepath, text)
    fid = fopen(char(filepath), "w", "n", "UTF-8");
    if fid < 0
        error("eis:syntheticInputs:SampleWriteFailed", "Could not write synthetic input file: %s.", filepath);
    end
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", char(text));
end

function value = tab()
    value = char(9);
end
