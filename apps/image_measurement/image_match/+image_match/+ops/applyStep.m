% Expected caller: image_match.ops.applyPipeline and focused tests. Inputs are
% one RGB image, one reference-match step, and an optional reference image.
% Output is RGB double image data in [0, 1].
function outputImage = applyStep(inputImage, step, referenceImage)

    outputImage = image_match.ops.applyMatch(inputImage, referenceImage, step);
end
