function varargout = labkit_FLIRThermal_app(varargin)
%LABKIT_FLIRTHERMAL_APP FLIR radiometric image post-processing app.

    [varargout{1:nargout}] = labkit.ui.runtime.launch( ...
        @flir_thermal.definition, @flir_thermal.requirements, ...
        @flir_thermal.version, varargin{:});
end
