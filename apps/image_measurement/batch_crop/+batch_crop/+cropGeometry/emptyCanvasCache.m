% App-owned geometry-cache factory. Expected caller: batch-crop reset,
% and image-change callbacks. Output is the scalar cache state for prepared
% crop preview canvases. No file or graphics side effects occur here.
function cache = emptyCanvasCache()
%EMPTYCANVASCACHE Return an invalid prepared-canvas cache.

    cache = struct('valid', false, 'key', [], 'geometry', []);
end
