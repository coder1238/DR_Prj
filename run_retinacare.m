% RUN_RETINACARE Launcher for RetinaCare AI MATLAB App Designer Application
%
% Usage in MATLAB:
%   >> run_retinacare
%
% This script ensures all subfolders are added to the MATLAB path and
% starts the RetinaCareApp graphical interface.

fprintf('========================================================================\n');
fprintf('  RetinaCare AI - Smart DR Screening & Clinical Decision Support       \n');
fprintf('  Compliant with Stitch Project 8514012087795404150 Specifications     \n');
fprintf('========================================================================\n\n');

% Add project root and package directories to MATLAB path
projectRoot = fileparts(mfilename('fullpath'));
addpath(projectRoot);
addpath(fullfile(projectRoot, 'sample_data'));
rehash;

fprintf('[1/3] Added project root to MATLAB path: %s\n', projectRoot);

% Check MATLAB version
v = ver('matlab');
fprintf('[2/3] MATLAB Version detected: %s (%s)\n', v.Version, v.Release);

% Launch App Designer Application
fprintf('[3/3] Launching RetinaCareApp...\n');
try
    app = RetinaCareApp();
    fprintf('\n>>> RetinaCareApp launched successfully! UI Figure is active.\n');
    fprintf('    Explore all 15 clinical modules via the left navigation sidebar.\n\n');
catch ME
    fprintf('\nERROR launching RetinaCareApp:\n%s\n', ME.message);
    rethrow(ME);
end
