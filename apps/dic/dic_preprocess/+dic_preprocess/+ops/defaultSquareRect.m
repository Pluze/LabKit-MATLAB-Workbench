% Expected caller: DIC preprocess runner and direct unit tests. Input is an image
% size vector. Output is the default centered square crop rectangle. Side
% effects: none.

function rect = defaultSquareRect(imageSize)
%DEFAULTSQUARERECT Build the default centered DIC preprocess crop rectangle.

    H = imageSize(1);
    W = imageSize(2);
    side = max(1, round(0.5 * min(H, W)));
    x = round((W - side) / 2) + 1;
    y = round((H - side) / 2) + 1;
    rect = dic_preprocess.ops.squareRectInsideImage([x y side side], imageSize);
end
