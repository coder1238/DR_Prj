function mlappFile = build_mlapp()
% BUILD_MLAPP Converts RetinaCareApp.m into a native MATLAB App Designer .mlapp
% Uses m2mlapp to parse RetinaCareApp.m, instantiate all 15 modules,
% and serialize the genuine UIFigure into RetinaCareApp.mlapp.
%
% Usage in MATLAB:
%   >> build_mlapp
%   >> mlappFile = build_mlapp();

    appFolder = fileparts(mfilename('fullpath'));
    addpath(appFolder);
    addpath(fullfile(appFolder, 'sample_data'));
    rehash;

    mFile = fullfile(appFolder, 'RetinaCareApp.m');
    mlappFile = fullfile(appFolder, 'RetinaCareApp.mlapp');

    fprintf('==================================================================\n');
    fprintf(' RetinaCare AI — Building Native App Designer (.mlapp) Workstation\n');
    fprintf(' Modeled faithfully after retinacare-ai.zip (All 15 Modules)\n');
    fprintf('==================================================================\n\n');

    % 1. Invoke m2mlapp in MATLAB
    builtSuccess = false;
    try
        fprintf('• Invoking m2mlapp converter on RetinaCareApp.m...\n');
        result = m2mlapp(mFile, ...
            'Name', 'RetinaCareApp', ...
            'Description', 'RetinaCare AI — Smart DR Screening & Decision Support Workstation', ...
            'Version', '2.4', ...
            'Screenshot', true, ...
            'openApp', false);
        
        if ~isempty(result) && isfile(result)
            builtSuccess = true;
            fprintf('\n✓ SUCCESS: RetinaCareApp.mlapp successfully created via m2mlapp!\n');
        end
    catch ME
        fprintf('Note on m2mlapp execution: %s\n', ME.message);
    end

    % 2. Fallback to Python OPC Packager if m2mlapp couldn't complete
    if ~builtSuccess
        pyScript = fullfile(appFolder, 'build_mlapp.py');
        if isfile(pyScript)
            fprintf('• Invoking Python Open Packaging Conventions (OPC) packager...\n');
            [status, cmdout] = system(sprintf('python3 "%s"', pyScript));
            if status == 0
                fprintf('%s\n', cmdout);
                builtSuccess = true;
            end
        end
    end

    if isfile(mlappFile)
        info = dir(mlappFile);
        fprintf('\n📦 App Designer Package Info:\n');
        fprintf('   - File:     %s\n', info.name);
        fprintf('   - Size:     %d bytes (%.1f KB)\n', info.bytes, info.bytes/1024);
        fprintf('   - Location: %s\n\n', mlappFile);
        fprintf('To open and edit in MATLAB App Designer:\n');
        fprintf('   >> appdesigner(''%s'')\n\n', mlappFile);
        fprintf('To launch the live application in MATLAB:\n');
        fprintf('   >> run_retinacare\n');
        fprintf('==================================================================\n');
    end
end
