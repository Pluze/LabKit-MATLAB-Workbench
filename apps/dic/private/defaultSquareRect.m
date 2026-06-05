% App-owned DIC helper extracted from labkit_DICPreprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function rect = defaultSquareRect(imageSize)
    H = imageSize(1);
    W = imageSize(2);
    side = max(1, round(0.5 * min(H, W)));
    x = round((W - side) / 2) + 1;
    y = round((H - side) / 2) + 1;
    rect = squareRectInsideImage([x y side side], imageSize);
end
