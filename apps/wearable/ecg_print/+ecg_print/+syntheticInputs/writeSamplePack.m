% Expected caller: ecg_print.run during synthetic-input generation and unit tests. Input is
% a LabKit debug context. Output is a deterministic synthetic ECG recording
% sample pack. Side effects: writes anonymous debug files and records a
% synthetic-input manifest.
function pack = writeSamplePack(sampleContext)
%WRITESAMPLEPACK Write ECG Print debug recording files.
    arguments
        sampleContext (1, 1) labkit.app.synthetic.Context
    end

    csvPath = sampleContext.samplePath("ecg_print/recording.csv");
    headerlessPath = sampleContext.samplePath("ecg_print/headerless.txt");
    malformedPath = sampleContext.samplePath("ecg_print/malformed.csv");

    fs = 500;
    durationSec = 3;
    time = (0:(1 / fs):durationSec).';
    ecg = syntheticEcg(time, 1.15);
    motion = 0.10 .* sin(2 .* pi .* 0.7 .* time) + 0.035 .* sin(2 .* pi .* 3.3 .* time);
    contact = 1.0 + 0.06 .* sin(2 .* pi .* 0.05 .* time) + 0.02 .* syntheticNoise(time, 0.37);
    T = table(time, ecg, motion, contact, ...
        'VariableNames', {'time_s', 'ECG', 'Motion', 'ContactQuality'});
    writetable(T, char(csvPath));

    headerless = [time, syntheticEcg(time, 0.72), motion];
    writematrix(headerless, char(headerlessPath), "Delimiter", "\t");
    writeTextFile(malformedPath, ["time_s,ECG"; "0,ok"; "1,not_numeric"]);

    project = ecg_print.initialData();
    project.inputs.sources = sampleContext.sourceRecord( ...
        "recording1", "recording", csvPath);
    pack = labkit.app.synthetic.Pack( ...
        Scenario="representative-ecg", InitialInput=project, ...
        Artifacts={ ...
            sampleContext.artifact("recording", "recording", csvPath), ...
            sampleContext.artifact("headerless", ...
                "boundaryInput", headerlessPath), ...
            sampleContext.artifact("malformed", "boundaryInput", ...
                malformedPath, Expectation="rejects")});
end

function y = syntheticEcg(time, gain)
    beatTimes = 0.62:0.82:max(time);
    y = 0.03 .* sin(2 .* pi .* 0.24 .* time) + 0.012 .* syntheticNoise(time, 0.19);
    for k = 1:numel(beatTimes)
        t0 = beatTimes(k) + 0.018 .* sin(k .* 0.7);
        y = y + gain .* ( ...
            0.075 .* exp(-((time - (t0 - 0.16)) ./ 0.030).^2) ...
            -0.11 .* exp(-((time - (t0 - 0.026)) ./ 0.010).^2) ...
            +0.95 .* exp(-((time - t0) ./ 0.012).^2) ...
            -0.22 .* exp(-((time - (t0 + 0.030)) ./ 0.014).^2) ...
            +0.20 .* exp(-((time - (t0 + 0.25)) ./ 0.070).^2));
    end
end

function noise = syntheticNoise(time, phase)
    noise = sin(2 .* pi .* 17.3 .* time + phase) + ...
        0.5 .* sin(2 .* pi .* 41.7 .* time + 2 .* phase);
end

function writeTextFile(filepath, lines)
    fid = fopen(char(filepath), "w");
    if fid < 0
        error("ecg_print:syntheticInputs:SampleWriteFailed", "Could not write synthetic input file: %s.", filepath);
    end
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, "%s\n", lines);
end
