% Expected caller: image_match.definition during synthetic-input generation and unit tests. Input
% is a LabKit debug context. Output is a deterministic synthetic reference
% matching sample pack. Side effects: writes anonymous debug images and
% writes the synthetic-input manifest.
function pack = writeSamplePack(sampleContext)
%WRITESAMPLEPACK Write Image Match debug image files.
    arguments
        sampleContext (1, 1) labkit.app.synthetic.Context
    end

    referencePath = sampleContext.samplePath("image_match/reference.png");
    sourceWarmPath = sampleContext.samplePath("image_match/warm.png");
    sourceDimPath = sampleContext.samplePath("image_match/dim.png");
    edgePath = sampleContext.samplePath("image_match/size_mismatch.png");
    malformedPath = sampleContext.samplePath("image_match/malformed.png");

    reference = sceneImage("reference", [240 320]);
    imwrite(toUint8(reference), char(referencePath));
    imwrite(toUint8(sceneImage("warm", [240 320])), char(sourceWarmPath));
    imwrite(toUint8(sceneImage("dim", [240 320])), char(sourceDimPath));
    imwrite(toUint8(sceneImage("warm", [180 260])), char(edgePath));
    writeTextFile(malformedPath, "not an image payload" + newline);

    project = image_match.initialData();
    project.inputs.reference = sampleContext.sourceRecord( ...
        "reference1", "reference-image", referencePath, true);
    project.inputs.sources = [ ...
        sampleContext.sourceRecord( ...
            "image1", "source-image", sourceWarmPath, true), ...
        sampleContext.sourceRecord( ...
            "image2", "source-image", sourceDimPath, true)];
    pack = labkit.app.synthetic.Pack( ...
        Scenario="representative-image-match", InitialInput=project, ...
        Artifacts={ ...
            sampleContext.artifact( ...
                "reference", "reference-image", referencePath), ...
            sampleContext.artifact("warm", "source-image", sourceWarmPath), ...
            sampleContext.artifact("dim", "source-image", sourceDimPath), ...
            sampleContext.artifact( ...
                "sizeMismatch", "boundaryInput", edgePath), ...
            sampleContext.artifact("malformed", "boundaryInput", ...
                malformedPath, Expectation="rejects")});
end

function image = sceneImage(kind, dims)
    rows = dims(1);
    cols = dims(2);
    [x, y] = meshgrid(linspace(-1, 1, cols), linspace(-1, 1, rows));
    base = 0.55 + 0.15 .* x - 0.08 .* y + 0.08 .* sin(30 .* x + 6 .* y);
    target = exp(-((x + 0.28).^2 + (y - 0.18).^2) ./ 0.015) + ...
        0.7 .* exp(-((x - 0.35).^2 + (y + 0.22).^2) ./ 0.020);
    image = repmat(min(max(base + 0.20 .* target, 0), 1), 1, 1, 3);
    image(:, :, 1) = image(:, :, 1) + 0.08 .* target;
    image(:, :, 2) = image(:, :, 2) + 0.04 .* sin(4 .* y);
    image(:, :, 3) = image(:, :, 3) .* 0.92;
    switch kind
        case "warm"
            image(:, :, 1) = min(image(:, :, 1) .* 1.20 + 0.04, 1);
            image(:, :, 3) = image(:, :, 3) .* 0.78;
        case "dim"
            image = image .* 0.72 + 0.08;
            image(:, :, 2) = min(image(:, :, 2) .* 1.12, 1);
    end
    image = min(max(image, 0), 1);
end

function image = toUint8(image)
    image = uint8(round(255 .* min(max(image, 0), 1)));
end

function writeTextFile(filepath, text)
    fid = fopen(char(filepath), "w", "n", "UTF-8");
    if fid < 0
        error("image_match:syntheticInputs:SampleWriteFailed", ...
            "Could not write synthetic input file: %s.", filepath);
    end
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", char(text));
end
