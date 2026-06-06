% DIC family private helper. Expected caller: remaining DIC postprocess image
% helpers. Input is image data. Output is normalized grayscale data. Side
% effects: none.
function gray = normalizeGray(imageData)
    if ndims(imageData) == 3
        gray = rgb2gray(imageData);
    else
        gray = imageData;
    end
    gray = im2double(gray);
    values = gray(:);
    values = values(~isnan(values));
    if isempty(values)
        return;
    end
    mn = min(values);
    mx = max(values);
    if isfinite(mn) && isfinite(mx) && mx > mn
        gray = (gray - mn) ./ (mx - mn);
    end
end
