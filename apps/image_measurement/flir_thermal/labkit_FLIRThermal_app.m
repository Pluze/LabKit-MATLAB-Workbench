function varargout = labkit_FLIRThermal_app(varargin)
%LABKIT_FLIRTHERMAL_APP FLIR radiometric image post-processing app.

    [varargout{1:nargout}] = flir_thermal.definition().launch(varargin{:});
end
