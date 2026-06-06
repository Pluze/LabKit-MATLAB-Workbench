% Expected caller: DIC preprocess runner and direct unit tests. Inputs are the
% current ROI mask image and destination path. Output is the written path. Side
% effect: writes one PNG image file.

function outfile = writeMask(maskImage, outfile)
%WRITEMASK Write the DIC preprocess ROI mask image.

    imwrite(maskImage, outfile);
end
