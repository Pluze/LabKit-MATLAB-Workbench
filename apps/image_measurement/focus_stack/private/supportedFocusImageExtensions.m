% App-owned focus-stack extension list helper. Expected caller: focus-stack app
% private loading helpers. Output is a cell array of lowercase extension strings
% and the helper has no side effects.
function extensions = supportedFocusImageExtensions()
%SUPPORTEDFOCUSIMAGEEXTENSIONS Return supported focus-stack image extensions.
% Expected caller: focus-stack app private loading helpers. Output is a cell
% array of lowercase extension strings. This helper has no side effects.

    extensions = {'.png', '.jpg', '.jpeg', '.tif', '.tiff', '.bmp'};
end
