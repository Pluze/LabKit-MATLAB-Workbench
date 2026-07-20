% Expected caller: FLIR UI rendering and export option normalization. Input is
% a user-provided gamma value. Output is a finite scalar clamped to the
% app-supported display range.

function value = normalizeGammaValue(value)
%NORMALIZEGAMMAVALUE Normalize FLIR display gamma to a supported scalar.

    value = double(value);
    if ~isscalar(value) || ~isfinite(value)
        value = 2.2;
    end
    value = min(5, max(0.1, value));
end
