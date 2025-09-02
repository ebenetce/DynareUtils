function varargout = set_dynare_seed(a,b, nvp)
% Set seeds depending on matlab (octave) version. This routine is called in dynare_config and can be called by the
% user in the mod file.
%
% Copyright (C) 2010-2020 Dynare Team
%
% This file is part of Dynare.
%
% Dynare is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% Dynare is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with Dynare.  If not, see <https://www.gnu.org/licenses/>.
arguments
    a
    b {mustBeInteger} = [];
    nvp.Options struct = struct.empty();
end

if ~isempty(nvp.Options)
    options_ = nvp.Options;
end

if ~nargin
    error('set_dynare_seed:: I need at least one input argument!')
end


if isempty(b)
    if ischar(a) && strcmpi(a,'default')
        options_.DynareRandomStreams.algo = 'mt19937ar';
        options_.DynareRandomStreams.seed = 0;
        s = RandStream(options_.DynareRandomStreams.algo,'Seed',options_.DynareRandomStreams.seed);
        reset(RandStream.setGlobalStream(s));
        varargout{1} = options_;
        return
    end
    if ischar(a) && strcmpi(a,'reset')
        s = RandStream(options_.DynareRandomStreams.algo,'Seed',options_.DynareRandomStreams.seed);
        reset(RandStream.setGlobalStream(s));
        return
    end
    if ~ischar(a) || (ischar(a) && strcmpi(a, 'clock'))
        algo = 'mt19937ar';
        if ischar(a)
            seed = rem(floor(now*24*60*60), 2^32);
        else
            seed = a;
        end
        s = RandStream(algo,'Seed',seed);
        reset(RandStream.setGlobalStream(s));
        if nargout == 1
            options_.DynareRandomStreams.algo = algo;
            options_.DynareRandomStreams.seed = seed;
            varargout{1} = options_;
        end
        return
    end
    error('set_dynare_seed:: something is wrong in the calling sequence!')
else
    if ~ischar(a) || ~( strcmpi(a,'mcg16807') || ...
            strcmpi(a,'mlfg6331_64') || ...
            strcmpi(a,'mrg32k3a') || ...
            strcmpi(a,'mt19937ar') || ...
            strcmpi(a,'shr3cong') || ...
            strcmpi(a,'swb2712') )
        disp('set_dynare_seed:: First argument must be string designing the uniform random number algorithm!')
        RandStream.list
        skipline()
        disp('set_dynare_seed:: Change the first input accordingly...')
        skipline()
        error(' ')
    end
    if ~isint(b)
        error('set_dynare_seed:: The second input argument must be an integer!')
    end
    
    s = RandStream(a,'Seed',b);
    reset(RandStream.setGlobalStream(s));
    if nargout == 1
        options_.DynareRandomStreams.algo = a;
        options_.DynareRandomStreams.seed = b;
        varargout{1} = options_;
    end    
end