function mlappFile = build_mlapp()
% BUILD_MLAPP Builds and packages RetinaCareApp.mlapp from RetinaCareApp.m
% Complies with MATLAB App Designer Open Packaging Conventions (OPC).
%
% Usage:
%   build_mlapp
%   mlappFile = build_mlapp();

    appFolder = fileparts(mfilename('fullpath'));
    mFile = fullfile(appFolder, 'RetinaCareApp.m');
    mlappFile = fullfile(appFolder, 'RetinaCareApp.mlapp');

    if ~isfile(mFile)
        error('Source file RetinaCareApp.m not found in %s', appFolder);
    end

    fprintf('==================================================================\n');
    fprintf(' RetinaCare AI — Building MATLAB App Designer (.mlapp) Package\n');
    fprintf('==================================================================\n\n');

    % Try MATLAB App Designer native serialization if available
    builtNative = false;
    try
        if exist('appdesigner.internal.serialization.MLAPPSerializer', 'class') == 8
            fprintf('• Detected MATLAB App Designer MLAPPSerializer API...\n');
            appObj = RetinaCareApp();
            uiFig = appObj.UIFigure;
            serializer = appdesigner.internal.serialization.MLAPPSerializer(mlappFile, uiFig);
            serializer.ClassName = 'RetinaCareApp';
            serializer.MatlabCodeText = fileread(mFile);
            serializer.Metadata.Name = 'RetinaCareApp';
            serializer.Metadata.Author = 'RetinaCare AI Engineering Team';
            serializer.Metadata.Version = '2.4';
            serializer.Metadata.Description = 'Smart DR Screening & Clinical Decision Support Tele-Ophthalmology Workstation';
            serializer.save();
            delete(appObj);
            builtNative = true;
            fprintf('✓ Successfully serialized RetinaCareApp.mlapp via MLAPPSerializer.\n');
        end
    catch ME
        % If native serializer failed or headless figure not permitted, fallback to OPC packager
        fprintf('ℹ Note on native serializer: %s\n', ME.message);
    end

    if ~builtNative
        % Use Python OPC packager (build_mlapp.py)
        pyScript = fullfile(appFolder, 'build_mlapp.py');
        if isfile(pyScript)
            fprintf('• Invoking Open Packaging Conventions (OPC) packager...\n');
            [status, cmdout] = system(sprintf('python3 "%s"', pyScript));
            if status == 0
                fprintf('%s\n', cmdout);
                fprintf('✓ Successfully created %s\n', mlappFile);
            else
                fprintf('Warning: Python packager returned code %d:\n%s\n', status, cmdout);
            end
        else
            fprintf('Package %s is ready.\n', mlappFile);
        end
    end

    if isfile(mlappFile)
        info = dir(mlappFile);
        fprintf('\n📦 Package Info:\n');
        fprintf('   - File: %s\n', info.name);
        fprintf('   - Size: %d bytes (%.1f KB)\n', info.bytes, info.bytes/1024);
        fprintf('   - Path: %s\n\n', mlappFile);
        fprintf('To open in App Designer:\n');
        fprintf('   appdesigner(''%s'')\n\n', mlappFile);
        fprintf('To run the app directly in MATLAB:\n');
        fprintf('   run_retinacare\n');
        fprintf('==================================================================\n');
    end
end
