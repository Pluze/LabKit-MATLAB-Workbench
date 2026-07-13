% App-owned focus-stack preview normalization helper. Expected caller:
% labkit_FocusStack_app preview refresh. Input is an image array. Output is a
% double preview image with at most three channels.
function img = previewImage(img)
%PREVIEWIMAGE Normalize an image for focus-stack preview display.

    img = labkit.image.ensureRgb(labkit.image.im2double(img));
    img = min(max(img, 0), 1);
end
