% Expected caller: app debug launch and unit tests. Input
% is a LabKit debug context. Output is a deterministic synthetic crop sample
% pack. Side effects: writes anonymous debug images and records a session
% manifest when available.
function pack = writeSamplePack(sampleContext)
%WRITESAMPLEPACK Write Batch Crop debug image files.
    arguments
        sampleContext (1, 1) labkit.app.diagnostic.SampleContext
    end

    imageA = sampleContext.samplePath("batch_crop/source_a.png");
    imageB = sampleContext.samplePath("batch_crop/source_b.png");
    edgePath = sampleContext.samplePath("batch_crop/small_target.png");
    malformedPath = sampleContext.samplePath("batch_crop/malformed.png");
    imwrite(targetImage(0), char(imageA));
    imwrite(targetImage(1), char(imageB));
    imwrite(targetImage(2), char(edgePath));
    writeTextFile(malformedPath, "not an image payload" + newline);

    project = batch_crop.projectSpec().Create();
    project.inputs.sources = [ ...
        sampleContext.sourceRecord("image1", "cropSource", imageA, true), ...
        sampleContext.sourceRecord("image2", "cropSource", imageB, true)];
    project.inputs.items = batch_crop.cropTasks.forSourceIds( ...
        string({project.inputs.sources.id}));
    pack = labkit.app.diagnostic.SamplePack( ...
        Scenario="representative-crop-targets", InitialProject=project, ...
        Artifacts={ ...
            sampleContext.artifact("sourceA", "cropSource", imageA), ...
            sampleContext.artifact("sourceB", "cropSource", imageB), ...
            sampleContext.artifact("smallTarget", "boundaryInput", edgePath), ...
            sampleContext.artifact("malformed", "boundaryInput", ...
                malformedPath, Expectation="rejects")});
end

function image = targetImage(variant)
    [x, y] = meshgrid(1:340, 1:260);
    base = 0.52 + 0.10 .* sin(0.05 .* x) + 0.07 .* sin(0.08 .* y);
    centers = [118 132; 230 150; 175 82];
    if variant == 1
        centers = centers + [16 -8; -12 10; 8 12];
    elseif variant == 2
        centers = [170 130; 190 145; 205 118];
    end
    image = repmat(base, 1, 1, 3);
    for k = 1:size(centers, 1)
        r = hypot(x - centers(k, 1), y - centers(k, 2));
        ring = r > 14 & r < 20;
        core = r < 8;
        image(:, :, 1) = image(:, :, 1) + 0.24 .* ring + 0.10 .* core;
        image(:, :, 2) = image(:, :, 2) + 0.18 .* ring + 0.05 .* core;
        image(:, :, 3) = image(:, :, 3) + 0.05 .* ring;
    end
    scaleCue = x > 42 & x < 112 & y > 226 & y < 232;
    image = image + 0.30 .* scaleCue;
    image = uint8(round(255 .* min(max(image, 0), 1)));
end

function writeTextFile(filepath, text)
    fid = fopen(char(filepath), "w", "n", "UTF-8");
    if fid < 0
        error("batch_crop:debug:SampleWriteFailed", ...
            "Could not write debug sample file: %s.", filepath);
    end
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", char(text));
end
