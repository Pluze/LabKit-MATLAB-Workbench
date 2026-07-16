function varargout = labkit_DICPostprocess_app(varargin)
%LABKIT_DICPOSTPROCESS_APP Ncorr strain summary and overlay export app.
% Thin entrypoint delegates all product metadata and launch behavior to the
% single app definition.
    [varargout{1:nargout}] = labkit.ui.runtime.launch( ...
        @dic_postprocess.definition, varargin{:});
end
