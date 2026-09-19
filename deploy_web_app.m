function deploy_web_app(varargin)
% DEPLOY_WEB_APP Packages and deploys RetinaCareApp for MATLAB Web App Server
%
% Usage:
%   >> deploy_web_app
%   >> deploy_web_app('ServerAppsDir', '/usr/local/MATLAB/MATLAB_Web_App_Server/R2024b/apps')
%   >> deploy_web_app('OutputDir', './dist')
%
% Description:
%   This utility script compiles the RetinaCareApp App Designer application
%   into a MATLAB Web App Archive (.ctf) using MATLAB Compiler.
%   The resulting archive can be dropped directly into the 'apps' folder of
%   a running MATLAB Web App Server instance.
%
% Requirements:
%   - MATLAB R2020b or later
%   - MATLAB Compiler toolbox license
%   - MATLAB Web App Server (running on localhost:9988 or remote host)

    fprintf('========================================================================\n');
    fprintf('  RetinaCare AI - MATLAB Web App Server Deployment Pipeline             \n');
    fprintf('  Target: MATLAB Web App Server (.ctf Web Archive)                      \n');
    fprintf('========================================================================\n\n');

    p = inputParser;
    addParameter(p, 'ServerAppsDir', '', @ischar);
    addParameter(p, 'OutputDir', '', @ischar);
    parse(p, varargin{:});

    projectRoot = fileparts(mfilename('fullpath'));
    outputDir = p.Results.OutputDir;
    if isempty(outputDir)
        outputDir = fullfile(projectRoot, 'dist');
    end
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    % 1. Verify MATLAB Compiler License and Availability
    fprintf('[1/4] Checking MATLAB Compiler availability...\n');
    hasCompiler = ~isempty(ver('compiler')) && license('test', 'Compiler');
    if ~hasCompiler
        warning(['MATLAB Compiler is required to build .ctf archives for MATLAB Web App Server.\n' ...
                 'Please ensure MATLAB Compiler is installed and activated.']);
    else
        fprintf('      MATLAB Compiler detected and licensed.\n');
    end

    % 2. Prepare Source and Additional Files
    fprintf('[2/4] Preparing application assets and dependencies...\n');
    mainAppFile = fullfile(projectRoot, 'RetinaCareApp.m');
    packageDir = fullfile(projectRoot, '+retinacare');
    sampleDataDir = fullfile(projectRoot, 'sample_data');

    additionalFiles = {};
    if exist(packageDir, 'dir')
        additionalFiles{end+1} = packageDir;
    end
    if exist(sampleDataDir, 'dir')
        additionalFiles{end+1} = sampleDataDir;
    end

    % 3. Compile Web App Archive (.ctf)
    fprintf('[3/4] Building Web App archive using compiler.build.webApp...\n');
    fprintf('      Main App: %s\n', mainAppFile);
    fprintf('      Output Directory: %s\n', outputDir);

    archiveName = 'RetinaCareApp';
    try
        if hasCompiler
            buildOptions = compiler.build.WebAppOptions(mainAppFile, ...
                'OutputDir', outputDir, ...
                'ArchiveName', archiveName, ...
                'AdditionalFiles', additionalFiles);
            
            buildResult = compiler.build.webApp(buildOptions);
            fprintf('      Build complete! Archive generated:\n');
            fprintf('      -> %s\n', fullfile(outputDir, [archiveName, '.ctf']));
        else
            fprintf('      [DRY RUN] To compile manually once MATLAB Compiler is available, run:\n');
            fprintf('      >> opts = compiler.build.WebAppOptions(''%s'', ''OutputDir'', ''%s'', ''ArchiveName'', ''%s'');\n', mainAppFile, outputDir, archiveName);
            fprintf('      >> compiler.build.webApp(opts);\n');
        end
    catch ME
        fprintf('Build encountered error:\n%s\n', ME.message);
        fprintf('Fallback: You can also use App Designer -> Share -> Web App.\n');
    end

    % 4. Deploy to MATLAB Web App Server apps directory
    fprintf('[4/4] Locating MATLAB Web App Server apps directory...\n');
    targetServerDir = p.Results.ServerAppsDir;
    if isempty(targetServerDir)
        envDir = getenv('MW_WAS_APPS_DIR');
        if ~isempty(envDir)
            targetServerDir = envDir;
        end
    end

    % Common default paths for MATLAB Web App Server
    candidatePaths = {
        targetServerDir, ...
        '/usr/local/MATLAB/MATLAB_Web_App_Server/apps', ...
        'C:\Program Files\MATLAB\MATLAB Web App Server\apps', ...
        'C:\ProgramData\MathWorks\webapps'
    };

    deployed = false;
    ctfFile = fullfile(outputDir, [archiveName, '.ctf']);
    for i = 1:length(candidatePaths)
        cand = candidatePaths{i};
        if ~isempty(cand) && exist(cand, 'dir')
            try
                copyfile(ctfFile, fullfile(cand, [archiveName, '.ctf']));
                fprintf('      Successfully deployed %s to %s!\n', [archiveName, '.ctf'], cand);
                deployed = true;
                break;
            catch e
                fprintf('      Could not copy to %s: %s\n', cand, e.message);
            end
        end
    end

    if ~deployed
        fprintf('      Notice: No active MATLAB Web App Server apps folder was auto-detected.\n');
        fprintf('      To deploy manually:\n');
        fprintf('      Copy %s into your MATLAB Web App Server `apps/` directory.\n', ctfFile);
    end

    fprintf('\n========================================================================\n');
    fprintf('  MATLAB Web App Server Access Instructions:                            \n');
    fprintf('  1. Verify the server daemon is running:                               \n');
    fprintf('     Linux:   sudo mw_was_status   (or systemctl status mw-webapps-*)   \n');
    fprintf('     Windows: MATLAB Web App Server Service in services.msc             \n');
    fprintf('  2. Open your web browser and navigate to:                             \n');
    fprintf('     http://<server-host>:9988/webapps/home/                            \n');
    fprintf('  3. Click on "RetinaCareApp" to launch the clinical workstation!       \n');
    fprintf('========================================================================\n\n');
end
