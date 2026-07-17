function varargout = labkit_BatchImageCrop_app(varargin)
%LABKIT_BATCHIMAGECROP_APP Batch crop microscope images at fixed pixel size.
% Thin entrypoint delegates requests, launch, and version title to runtime V2.
    [varargout{1:nargout}] = labkit.ui.runtime.launch( ...
        @batch_crop.definition, varargin{:});
end
