% Expected caller: app synthetic-input generation and unit tests. Input
% is a LabKit debug context. Output is a deterministic synthetic focus-stack
% sample pack. Side effects: writes anonymous debug images and records a
% session manifest when available.
function pack = writeSamplePack(sampleContext)
%WRITESAMPLEPACK Write Focus Stack debug image files.
    arguments
        sampleContext (1, 1) labkit.app.synthetic.Context
    end

    [base, detailMask] = baseScene();
    slicePaths = strings(4, 1);
    focusCenters = [52 108 164 220];
    for k = 1:numel(slicePaths)
        image = focusSlice(base, detailMask, focusCenters(k));
        slicePaths(k) = sampleContext.samplePath( ...
            sprintf("focus_stack/slice_%02d.png", k));
        imwrite(image, char(slicePaths(k)));
    end

    lowTexturePath = sampleContext.samplePath("focus_stack/low_texture.png");
    imwrite(lowTextureImage(), char(lowTexturePath));
    malformedPath = sampleContext.samplePath("focus_stack/malformed.png");
    writeTextFile(malformedPath, "not an image payload" + newline);

    project = focus_stack.projectSpec().Create();
    artifacts = cell(1, numel(slicePaths) + 2);
    for k = 1:numel(slicePaths)
        sourceId = "image" + k;
        project.inputs.sources(k) = sampleContext.sourceRecord( ...
            sourceId, "focus-image", slicePaths(k), true);
        artifacts{k} = sampleContext.artifact( ...
            sourceId, "focus-image", slicePaths(k));
    end
    artifacts{end - 1} = sampleContext.artifact( ...
        "lowTexture", "boundaryInput", lowTexturePath);
    artifacts{end} = sampleContext.artifact( ...
        "malformed", "boundaryInput", malformedPath, ...
        Expectation="rejects");
    pack = labkit.app.synthetic.Pack( ...
        Scenario="representative-focus-stack", ...
        InitialProject=project, Artifacts=artifacts);
end

function [image, detailMask] = baseScene()
    [x, y] = meshgrid(linspace(-1, 1, 256), linspace(-1, 1, 192));
    illumination = 0.62 + 0.18 .* x - 0.10 .* y + 0.05 .* sin(5 .* x);
    fibers = 0.10 .* sin(38 .* x + 8 .* y) + 0.06 .* sin(24 .* y);
    beads = exp(-((x + 0.35).^2 + (y - 0.20).^2) ./ 0.012) + ...
        0.8 .* exp(-((x - 0.28).^2 + (y + 0.18).^2) ./ 0.018) + ...
        0.6 .* exp(-((x - 0.05).^2 + (y - 0.40).^2) ./ 0.009);
    gray = min(max(illumination + fibers + 0.25 .* beads, 0), 1);
    image = repmat(gray, 1, 1, 3);
    image(:, :, 2) = min(max(image(:, :, 2) .* 1.05, 0), 1);
    image(:, :, 3) = min(max(image(:, :, 3) .* 0.92, 0), 1);
    detailMask = abs(fibers) + beads;
end

function image = focusSlice(base, detailMask, centerRow)
    blurred = meanBlur(base, 9);
    rows = (1:size(base, 1)).';
    focusBand = exp(-((rows - centerRow) ./ 34) .^ 2);
    focusBand = repmat(focusBand, 1, size(base, 2), 3);
    textureBoost = repmat(detailMask, 1, 1, 3) .* 0.05;
    image = blurred .* (1 - focusBand) + min(max(base + textureBoost, 0), 1) .* focusBand;
    image = toUint8(image);
end

function image = lowTextureImage()
    [x, y] = meshgrid(linspace(0, 1, 128), linspace(0, 1, 96));
    gray = 0.50 + 0.015 .* sin(2 .* pi .* x) + 0.01 .* y;
    image = toUint8(repmat(gray, 1, 1, 3));
end

function out = meanBlur(image, radius)
    kernel = ones(radius, radius) ./ (radius ^ 2);
    out = zeros(size(image));
    for channel = 1:size(image, 3)
        out(:, :, channel) = conv2(image(:, :, channel), kernel, "same");
    end
end

function image = toUint8(image)
    image = uint8(round(255 .* min(max(image, 0), 1)));
end

function writeTextFile(filepath, text)
    fid = fopen(char(filepath), "w", "n", "UTF-8");
    if fid < 0
        error("focus_stack:syntheticInputs:SampleWriteFailed", ...
            "Could not write synthetic input file: %s.", filepath);
    end
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, "%s", char(text));
end
