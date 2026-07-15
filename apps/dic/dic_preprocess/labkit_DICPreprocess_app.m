function varargout = labkit_DICPreprocess_app(varargin)
%LABKIT_DICPREPROCESS_APP Image registration and paired-crop app for DIC workflows.
% Thin entrypoint delegates requests, launch, and version title to runtime V2.
    [varargout{1:nargout}] = labkit.ui.runtime.launch( ...
        @dic_preprocess.definition, @dic_preprocess.requirements, ...
        @dic_preprocess.version, varargin{:});
end
