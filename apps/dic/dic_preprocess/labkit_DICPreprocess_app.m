function varargout = labkit_DICPreprocess_app(varargin)
%LABKIT_DICPREPROCESS_APP Image registration and paired-crop app for DIC workflows.
% Thin entrypoint delegates product metadata and launch behavior to one definition.
    [varargout{1:nargout}] = labkit.ui.runtime.launch( ...
        @dic_preprocess.definition, varargin{:});
end
