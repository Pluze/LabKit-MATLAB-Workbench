function varargout = labkit_ImageMatch_app(varargin)
%LABKIT_IMAGEMATCH_APP Reference image matching app for figure images.

    [varargout{1:nargout}] = image_match.definition().launch(varargin{:});
end
