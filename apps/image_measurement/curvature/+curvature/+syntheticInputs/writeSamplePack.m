% Expected caller: curvature.definition during synthetic-input generation and unit tests. Input
% is a LabKit debug context. Output is a deterministic synthetic curvature
% image sample pack. Side effects: writes anonymous debug images and records
% a session manifest when available.
function pack = writeSamplePack(sampleContext)
%WRITESAMPLEPACK Write Curvature debug image files.
    arguments
        sampleContext (1, 1) labkit.app.synthetic.Context
    end

    arcPath = sampleContext.samplePath("curvature/arc.png");
    edgePath = sampleContext.samplePath("curvature/low_contrast.png");
    malformedPath = sampleContext.samplePath("curvature/malformed.png");
    imwrite(arcImage(false), char(arcPath));
    imwrite(arcImage(true), char(edgePath));
    writeTextFile(malformedPath, "not an image payload" + newline);

    project = curvature.projectSpec().Create();
    project.inputs.sources = sampleContext.sourceRecord( ...
        "image1", "image", arcPath, true);
    pack = labkit.app.synthetic.Pack( ...
        Scenario="representative-arc", InitialProject=project, ...
        Artifacts={ ...
            sampleContext.artifact("arc", "image", arcPath), ...
            sampleContext.artifact("lowContrast", "boundaryInput", edgePath), ...
            sampleContext.artifact("malformed", "boundaryInput", ...
                malformedPath, Expectation="rejects")});
end

function image = arcImage(lowContrast)
    [x, y] = meshgrid(1:360, 1:260);
    cx = 180;
    cy = 255;
    radius = 165;
    distance = abs(hypot(x - cx, y - cy) - radius);
    arcMask = distance < 4 & y < 220 & x > 55 & x < 310;
    texture = 0.46 + 0.10 .* sin(0.08 .* x + 0.03 .* y) + ...
        0.05 .* sin(0.20 .* y);
    image = repmat(texture, 1, 1, 3);
    if lowContrast
        image = image + 0.06 .* arcMask;
    else
        image(:, :, 1) = image(:, :, 1) + 0.38 .* arcMask;
        image(:, :, 2) = image(:, :, 2) + 0.30 .* arcMask;
        image(:, :, 3) = image(:, :, 3) + 0.08 .* arcMask;
    end
    scaleCue = x > 250 & x < 315 & y > 222 & y < 228;
    image = image + 0.25 .* scaleCue;
    image = uint8(round(255 .* min(max(image, 0), 1)));
end

function writeTextFile(filepath, text)
    fid = fopen(char(filepath), "w", "n", "UTF-8");
    if fid < 0
        error("curvature:syntheticInputs:SampleWriteFailed", ...
            "Could not write synthetic input file: %s.", filepath);
    end
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", char(text));
end
