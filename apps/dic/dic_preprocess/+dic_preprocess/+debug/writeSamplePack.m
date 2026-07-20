% Expected caller: the App SDK debug-sample capability and unit tests.
% Input is a bounded diagnostic SampleContext. Output is a deterministic
% synthetic DIC image-pair SamplePack with a current project. Side effects:
% writes anonymous synthetic images beneath the context sample folder.
function pack = writeSamplePack(sampleContext)
%WRITESAMPLEPACK Write DIC preprocess debug image files.
    arguments
        sampleContext (1, 1) labkit.app.diagnostic.SampleContext
    end

    referencePath = sampleContext.samplePath( ...
        "dic_preprocess/reference.png");
    movingPath = sampleContext.samplePath( ...
        "dic_preprocess/moving.png");
    lowTexturePath = sampleContext.samplePath( ...
        "dic_preprocess/low_texture.png");
    malformedPath = sampleContext.samplePath( ...
        "dic_preprocess/malformed.png");

    ref = syntheticSpeckleImage(192, 256, 0, 0, 1);
    moving = syntheticSpeckleImage(192, 256, 4.2, -2.8, 0.96);
    lowTexture = uint8(round(255 .* min(1, max(0, 0.48 + 0.03 .* syntheticField(192, 256)))));

    imwrite(ref, char(referencePath));
    imwrite(moving, char(movingPath));
    imwrite(lowTexture, char(lowTexturePath));
    writeTextFile(malformedPath, ["not a png payload"; "boundary=malformed image"]);

    project = dic_preprocess.projectSpec().Create();
    project.inputs.sources = [ ...
        sampleContext.sourceRecord( ...
            "referenceImage", "referenceImage", referencePath, true), ...
        sampleContext.sourceRecord( ...
            "movingImage", "movingImage", movingPath, true)];
    artifacts = { ...
        sampleContext.artifact( ...
            "referenceImage", "referenceImage", referencePath), ...
        sampleContext.artifact( ...
            "movingImage", "movingImage", movingPath), ...
        sampleContext.artifact( ...
            "lowTextureImage", "boundaryInput", lowTexturePath), ...
        sampleContext.artifact( ...
            "malformedImage", "boundaryInput", malformedPath, ...
            Expectation="rejects")};
    pack = labkit.app.diagnostic.SamplePack( ...
        Scenario="representative-image-pair", ...
        InitialProject=project, Artifacts=artifacts);
end

function img = syntheticSpeckleImage(h, w, shiftX, shiftY, gain)
    [x, y] = meshgrid(1:w, 1:h);
    base = 0.38 + 0.08 .* sin((x + shiftX) ./ 13) + 0.06 .* cos((y + shiftY) ./ 17);
    speckle = syntheticField(h, w);
    fibers = 0.10 .* sin((x .* 0.10) + (y .* 0.035) + shiftX .* 0.15);
    cue = exp(-(((x - 176 - shiftX) ./ 28).^2 + ((y - 86 - shiftY) ./ 10).^2));
    gray = gain .* (base + 0.16 .* speckle + fibers + 0.22 .* cue);
    img = uint8(round(255 .* min(1, max(0, gray))));
end

function field = syntheticField(h, w)
    [x, y] = meshgrid(1:w, 1:h);
    field = 0.42 .* sin(x ./ 3.7) .* cos(y ./ 5.1) + ...
        0.31 .* sin((x + 2 .* y) ./ 8.3) + ...
        0.21 .* cos((2 .* x - y) ./ 11.0);
end

function writeTextFile(filepath, lines)
    fid = fopen(char(filepath), "w");
    if fid < 0
        error("dic_preprocess:debug:SampleWriteFailed", "Could not write debug sample file: %s.", filepath);
    end
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, "%s\n", lines);
end
