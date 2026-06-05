% App-owned preview fill helper. Expected caller: batch-crop app preview
% rendering. Inputs are image data and fill mode. Output is a scalar fill
% value compatible with rotateCanvas.
function value = previewFillValue(imageData, fillMode)
%PREVIEWFILLVALUE Resolve black/white preview fill value.

    if strcmp(char(string(fillMode)), 'White')
        if islogical(imageData)
            value = 1;
        elseif isinteger(imageData)
            value = double(intmax(class(imageData)));
        else
            maxPixel = max(double(imageData(:)));
            if maxPixel > 1
                value = 255;
            else
                value = 1;
            end
        end
    else
        value = 0;
    end
end
