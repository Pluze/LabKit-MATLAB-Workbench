function varargout = labkit_BatchImageCrop_app(varargin)
%LABKIT_BATCHIMAGECROP_APP Batch crop microscope images at fixed pixel size.
% Thin entrypoint delegates launch and version title to the App SDK.
    [varargout{1:nargout}] = batch_crop.definition().launch(varargin{:});
end
