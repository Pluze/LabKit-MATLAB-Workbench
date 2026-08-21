% Expected caller: image_enhance.definition during synthetic-input generation and unit tests.
% Input is a LabKit debug context. Output is a deterministic synthetic image
% enhancement sample pack. Side effects: writes anonymous debug images and
% writes the synthetic-input manifest.
function pack = writeSamplePack(sampleContext)
%WRITESAMPLEPACK Write Image Enhance debug image files.
    arguments
        sampleContext (1, 1) labkit.app.synthetic.Context
    end

    sourceA = sampleContext.samplePath("image_enhance/uneven.png");
    sourceB = sampleContext.samplePath("image_enhance/color_cast.png");
    edgePath = sampleContext.samplePath("image_enhance/low_contrast.tif");
    malformedPath = sampleContext.samplePath("image_enhance/malformed.png");

    imwrite(toUint8(sceneImage("uneven")), char(sourceA));
    imwrite(toUint8(sceneImage("colorCast")), char(sourceB));
    imwrite(uint16(round(65535 .* lowContrastScene())), char(edgePath));
    writeTextFile(malformedPath, "not an image payload" + newline);

    project = image_enhance.initialData();
    project.inputs.sources = [ ...
        sampleContext.sourceRecord( ...
            "image1", "source-image", sourceA, true), ...
        sampleContext.sourceRecord( ...
            "image2", "source-image", sourceB, true)];
    pack = labkit.app.synthetic.Pack( ...
        Scenario="representative-enhancement", InitialInput=project, ...
        Artifacts={ ...
            sampleContext.artifact("uneven", "source-image", sourceA), ...
            sampleContext.artifact("colorCast", "source-image", sourceB), ...
            sampleContext.artifact("lowContrast", "boundaryInput", edgePath), ...
            sampleContext.artifact("malformed", "boundaryInput", ...
                malformedPath, Expectation="rejects")});
end

function image = sceneImage(kind)
    [x, y] = meshgrid(linspace(-1, 1, 320), linspace(-1, 1, 240));
    illumination = 0.58 + 0.22 .* x - 0.15 .* y + 0.08 .* sin(4 .* x);
    fibers = 0.09 .* sin(42 .* x + 12 .* y) + 0.05 .* sin(35 .* y);
    inclusions = exp(-((x + 0.42).^2 + (y - 0.22).^2) ./ 0.010) + ...
        0.7 .* exp(-((x - 0.20).^2 + (y + 0.28).^2) ./ 0.018);
    neutralPatch = double(abs(x - 0.62) < 0.16 & abs(y + 0.55) < 0.10);
    base = min(max(illumination + fibers + 0.22 .* inclusions, 0), 1);
    image = repmat(base, 1, 1, 3);
    image = image .* (1 - 0.35 .* neutralPatch) + 0.72 .* neutralPatch;
    if kind == "colorCast"
        image(:, :, 1) = min(image(:, :, 1) .* 1.18, 1);
        image(:, :, 2) = min(image(:, :, 2) .* 1.02, 1);
        image(:, :, 3) = image(:, :, 3) .* 0.78;
    else
        image(:, :, 2) = min(image(:, :, 2) .* 1.05, 1);
        image(:, :, 3) = image(:, :, 3) .* 0.90;
    end
end

function image = lowContrastScene()
    [x, y] = meshgrid(linspace(0, 1, 220), linspace(0, 1, 160));
    gray = 0.48 + 0.025 .* sin(2 .* pi .* 8 .* x) + 0.018 .* y;
    image = min(max(repmat(gray, 1, 1, 3), 0), 1);
end

function image = toUint8(image)
    image = uint8(round(255 .* min(max(image, 0), 1)));
end

function writeTextFile(filepath, text)
    fid = fopen(char(filepath), "w", "n", "UTF-8");
    if fid < 0
        error("image_enhance:syntheticInputs:SampleWriteFailed", ...
            "Could not write synthetic input file: %s.", filepath);
    end
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", char(text));
end
