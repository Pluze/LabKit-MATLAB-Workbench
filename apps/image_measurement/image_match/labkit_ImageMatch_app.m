function varargout = labkit_ImageMatch_app(varargin)
%LABKIT_IMAGEMATCH_APP Reference image matching app for figure images.

    [varargout{1:nargout}] = labkit.ui.runtime.launch( ...
        @image_match.definition, @image_match.requirements, ...
        @image_match.version, varargin{:});
end
