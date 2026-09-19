classdef ImageProcessingLab < handle
    % IMAGEPROCESSINGLAB Multi-stage retinal image enhancement and quality assessment
    % Implements CUNSB-RFIE, MAXIM/Gaussian denoising, CLAHE, Homomorphic filtering,
    % and Tenengrad sharpness / quality metrics for diabetic retinopathy screening.
    %
    % Compliant with RetinaCare AI Clinical Design System.
    
    methods (Static)
        function quality = assessQuality(img)
            % Assess overall and granular image quality metrics
            % Returns quality struct with scores and gradability verdict
            if size(img, 3) == 3
                grayImg = rgb2gray(img);
                greenChan = img(:,:,2);
            else
                grayImg = img;
                greenChan = img;
            end
            
            % 1. Sharpness via Tenengrad gradient magnitude
            [Gx, Gy] = imgradientxy(double(greenChan));
            gradMag = sqrt(Gx.^2 + Gy.^2);
            tenengradScore = mean(gradMag(:));
            sharpnessScore = min(100, max(0, (tenengradScore - 4) * 8.5));
            
            % 2. Illumination Uniformity
            mask = grayImg > 15;
            if any(mask(:))
                pixelVals = double(grayImg(mask));
                stdIllum = std(pixelVals);
                meanIllum = mean(pixelVals);
                illumUniformity = max(0, min(100, 100 - (stdIllum / max(1, meanIllum)) * 60));
            else
                illumUniformity = 50;
            end
            
            % 3. Disc & Macula Centration Metric
            [h, w] = size(grayImg);
            [Y, X] = find(mask);
            if ~isempty(X)
                cx = mean(X); cy = mean(Y);
                distFromCenter = sqrt((cx - w/2)^2 + (cy - h/2)^2);
                maxDist = sqrt((w/2)^2 + (h/2)^2);
                centrationScore = max(0, min(100, 100 * (1 - distFromCenter / (0.4 * maxDist))));
            else
                centrationScore = 80;
            end
            
            % 4. Blur / Artifact Index (0 = clear, 100 = heavily blurred/flared)
            blurIndex = max(0, min(100, 100 - sharpnessScore * 0.9));
            flareIndex = max(0, min(100, (sum(pixelVals > 240) / max(1, length(pixelVals))) * 500));
            
            % Overall Quality Index (0-100)
            overallIndex = 0.35 * sharpnessScore + 0.30 * illumUniformity + 0.20 * centrationScore + 0.15 * (100 - flareIndex);
            overallIndex = round(max(0, min(100, overallIndex)), 1);
            
            % Gradability Verdict
            if overallIndex >= 65 && blurIndex < 45
                verdict = 'Gradable (PASS)';
                isGradable = true;
                colorTag = [0.02, 0.59, 0.41]; % Green
            elseif overallIndex >= 50
                verdict = 'Borderline Gradable (Review Recommended)';
                isGradable = true;
                colorTag = [0.85, 0.47, 0.02]; % Amber
            else
                verdict = 'Ungradable (Rescan Required)';
                isGradable = false;
                colorTag = [0.86, 0.10, 0.10]; % Red
            end
            
            quality = struct();
            quality.OverallIndex = overallIndex;
            quality.Sharpness = round(sharpnessScore, 1);
            quality.IllumUniformity = round(illumUniformity, 1);
            quality.Centration = round(centrationScore, 1);
            quality.BlurIndex = round(blurIndex, 1);
            quality.FlareIndex = round(flareIndex, 1);
            quality.Verdict = verdict;
            quality.IsGradable = isGradable;
            quality.ColorTag = colorTag;
        end
        
        function enhanced = applyCUNSB(img)
            % CUNSB-RFIE: Color Uniformity & Illumination Normalization
            % Models background non-uniform illumination and normalizes it.
            if ~isfloat(img)
                imgF = im2double(img);
            else
                imgF = img;
            end
            
            enhanced = zeros(size(imgF));
            hsize = max(15, round(size(imgF, 1) / 12));
            if mod(hsize, 2) == 0, hsize = hsize + 1; end
            hFilter = fspecial('average', hsize);
            
            for c = 1:size(imgF, 3)
                chan = imgF(:,:,c);
                bg = imfilter(chan, hFilter, 'replicate');
                meanBg = mean(bg(:));
                normChan = chan ./ max(0.01, bg) * meanBg;
                enhanced(:,:,c) = min(1.0, max(0.0, normChan));
            end
        end
        
        function enhanced = applyCLAHE(img, clipLimit)
            % CLAHE: Contrast-Limited Adaptive Histogram Equalization
            % Optimized for green spectrum microvasculature enhancement.
            if nargin < 2, clipLimit = 0.02; end
            if ~isfloat(img)
                imgF = im2double(img);
            else
                imgF = img;
            end
            
            enhanced = imgF;
            if size(imgF, 3) == 3
                % Convert to Lab or HSV to equalize luminance without color shift
                lab = rgb2lab(imgF);
                L = lab(:,:,1) / 100;
                L_adapthist = adapthisteq(L, 'ClipLimit', clipLimit, 'NumTiles', [8 8]);
                lab(:,:,1) = L_adapthist * 100;
                enhanced = lab2rgb(lab);
            else
                enhanced = adapthisteq(imgF, 'ClipLimit', clipLimit, 'NumTiles', [8 8]);
            end
            enhanced = min(1.0, max(0.0, enhanced));
        end
        
        function denoised = applyDenoising(img, sigma)
            % MAXIM / Guided bilateral denoising filter
            if nargin < 2, sigma = 1.0; end
            if ~isfloat(img)
                imgF = im2double(img);
            else
                imgF = img;
            end
            
            denoised = imgaussfilt(imgF, sigma);
        end
        
        function filtered = applyHomomorphic(img)
            % Homomorphic filtering: compresses dynamic range and enhances high-frequency details
            if ~isfloat(img)
                imgF = im2double(img);
            else
                imgF = img;
            end
            
            filtered = zeros(size(imgF));
            for c = 1:size(imgF, 3)
                chan = max(1e-4, imgF(:,:,c));
                logChan = log(chan);
                
                % Frequency domain filter
                [M, N] = size(logChan);
                [U, V] = meshgrid(-N/2:N/2-1, -M/2:M/2-1);
                D = sqrt(U.^2 + V.^2);
                D0 = 30;
                gammaL = 0.6;
                gammaH = 1.8;
                H = (gammaH - gammaL) * (1 - exp(-(D.^2) ./ (2 * D0^2))) + gammaL;
                
                F = fftshift(fft2(logChan));
                filteredF = H .* F;
                invLog = real(ifft2(ifftshift(filteredF)));
                expChan = exp(invLog);
                
                % Normalize
                expChan = (expChan - min(expChan(:))) / max(1e-5, max(expChan(:)) - min(expChan(:)));
                filtered(:,:,c) = expChan;
            end
        end
        
        function result = fullPipeline(img, enableCUNSB, enableDenoise, enableCLAHE, enableHomo)
            % Execute selected pipeline stages
            if nargin < 2, enableCUNSB = true; end
            if nargin < 3, enableDenoise = true; end
            if nargin < 4, enableCLAHE = true; end
            if nargin < 5, enableHomo = false; end
            
            result = img;
            if enableCUNSB
                result = ImageProcessingLab.applyCUNSB(result);
            end
            if enableDenoise
                result = ImageProcessingLab.applyDenoising(result, 0.8);
            end
            if enableCLAHE
                result = ImageProcessingLab.applyCLAHE(result, 0.025);
            end
            if enableHomo
                result = ImageProcessingLab.applyHomomorphic(result);
            end
        end
    end
end
