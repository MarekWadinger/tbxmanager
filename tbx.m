function varargout = tbx(varargin)
%TBX  Shorthand alias for tbxmanager.
%   tbx install pkg  is equivalent to  tbxmanager install pkg
    [varargout{1:nargout}] = tbxmanager(varargin{:});
end
