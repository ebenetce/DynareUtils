function out = dynareUtilsRoot()
%DYNAREUTILSROOT Return the root folder of the dynare-utils package.
%   OUT = DYNAREUTILSROOT() returns the full path to the parent folder of
%   the folder containing this function. This is useful for constructing
%   paths to files and resources shipped with the package.
%
%   Example:
%       root = dynareUtilsRoot();
%
%   Copyright 2024 - 2026 The MathWorks, Inc.

out = fileparts(fileparts(mfilename('fullpath')));