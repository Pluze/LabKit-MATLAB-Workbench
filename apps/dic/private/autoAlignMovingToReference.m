% App-owned DIC helper extracted from labkit_DICPreprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function [alignedImage, tformRigid, method] = autoAlignMovingToReference(referenceImage, movingImage)
    origClass = class(movingImage);
    fixedGray = normalizeGray(referenceImage);
    movingGray = normalizeGray(movingImage);

    try
        tformRigid = imregcorr(movingGray, fixedGray, 'rigid');
        method = 'phase-correlation rigid registration';
    catch
        tformRigid = imregcorr(movingGray, fixedGray, 'translation');
        method = 'phase-correlation translation registration';
    end

    Rfixed = imref2d(size(fixedGray));
    alignedImage = imwarp(movingImage, tformRigid, ...
        'OutputView', Rfixed, 'FillValues', 0);
    alignedImage = cast(alignedImage, origClass);
end
