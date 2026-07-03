% DIC Postprocess export helper. Expected caller: labkit_DICPostprocess_app.
% Input is an overlay RGB image and output path. Side effect: writes a clean
% PNG without axes, title, or colorbar at the overlay image pixel size.
function exportOverlayImage(overlayImage, outfile)
    if isfloat(overlayImage)
        overlayImage = dic_postprocess.analysisRun.clamp01(overlayImage);
    end
    imwrite(overlayImage, outfile);
end
