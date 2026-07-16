% Expected caller: Image Enhance layout, presenter, and tests. Output is the
% single app-owned list of legal enhancement tool labels.
function values = toolKinds()
    values = {'Brightness/contrast', 'Local contrast', 'Sharpen', ...
        'Hue/saturation', 'White balance', 'White ROI calibration', ...
        'Subject-preserving enhance'};
end
