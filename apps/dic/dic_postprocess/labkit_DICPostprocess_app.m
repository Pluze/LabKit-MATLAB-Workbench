function varargout = labkit_DICPostprocess_app(varargin)
%LABKIT_DICPOSTPROCESS_APP Ncorr strain summary and overlay export app.
% Thin entrypoint delegates requests, launch, and version title to runtime V2.
    [varargout{1:nargout}] = labkit.ui.runtime.launch( ...
        @dic_postprocess.definition, @dic_postprocess.requirements, ...
        @dic_postprocess.version, varargin{:});
end
