function varargout = labkit_FocusStack_app(varargin)
%LABKIT_FOCUSSTACK_APP Fuse a focus image stack into one all-in-focus image.

    [varargout{1:nargout}] = focus_stack.definition().launch(varargin{:});
end
