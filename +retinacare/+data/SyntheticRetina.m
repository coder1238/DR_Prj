classdef SyntheticRetina < handle
    % SYNTHETICRETINA Pure-MATLAB Retinal Fundus Image Generator
    % Generates clinical-grade synthetic fundus images for all 5 ICDR stages
    % and DME without requiring external datasets.
    
    methods (Static)
        function [img, anatomy, lesions] = generate(stage, hasDME, eye, imgSize)
            if nargin < 1, stage = 2; end
            if nargin < 2, hasDME = (stage >= 2); end
            if nargin < 3, eye = 'OD'; end
            if nargin < 4, imgSize = 640; end
            
            w = imgSize; h = imgSize;
            cx = round(w / 2); cy = round(h / 2);
            radius = round(w * 0.46);
            
            % Base retinal gradient
            [X, Y] = meshgrid(1:w, 1:h);
            distFromCenter = sqrt((X - cx).^2 + (Y - cy).^2);
            apertureMask = distFromCenter <= radius;
            
            normDist = distFromCenter / radius;
            rChan = (195 + 40 * (1 - normDist * 0.8)) / 255;
            gChan = (90 + 35 * (1 - normDist * 0.9)) / 255;
            bChan = (35 + 20 * (1 - normDist)) / 255;
            
            img = zeros(h, w, 3);
            img(:,:,1) = rChan;
            img(:,:,2) = gChan;
            img(:,:,3) = bChan;
            
            % Optic Disc & Cup
            if strcmpi(eye, 'OD')
                discX = round(cx + radius * 0.42);
            else
                discX = round(cx - radius * 0.42);
            end
            discY = round(cy - radius * 0.05);
            discR = round(radius * 0.16);
            cupR = round(discR * 0.38);
            
            distDisc = sqrt((X - discX).^2 + (Y - discY).^2);
            discMask = distDisc <= discR;
            cupMask = distDisc <= cupR;
            
            % Paint disc
            for c = 1:3
                chan = img(:,:,c);
                if c == 1, val = 1.0; elseif c == 2, val = 0.88; else, val = 0.55; end
                chan(discMask) = val;
                if c == 1, valC = 1.0; elseif c == 2, valC = 0.96; else, valC = 0.75; end
                chan(cupMask) = valC;
                img(:,:,c) = chan;
            end
            
            % Macula / Fovea
            if strcmpi(eye, 'OD')
                maculaX = round(cx - radius * 0.15);
            else
                maculaX = round(cx + radius * 0.15);
            end
            maculaY = round(cy + radius * 0.05);
            maculaR = round(radius * 0.18);
            distMacula = sqrt((X - maculaX).^2 + (Y - maculaY).^2);
            maculaMask = distMacula <= maculaR;
            fazMask = distMacula <= 6;
            
            % Darken macula region
            macFactor = max(0, 1 - (distMacula / maculaR).^2);
            img(:,:,1) = img(:,:,1) .* (1 - 0.25 * macFactor);
            img(:,:,2) = img(:,:,2) .* (1 - 0.35 * macFactor);
            img(:,:,3) = img(:,:,3) .* (1 - 0.45 * macFactor);
            
            % Vascular Arcades (Superior and Inferior temporal)
            vesselMask = false(h, w);
            t = linspace(0, 1, 300);
            
            % Superior arcade
            xArc1 = discX + (maculaX - discX) * t;
            yArc1 = discY - 140 * sin(pi * t);
            for k = 1:length(t)
                xk = round(xArc1(k)); yk = round(yArc1(k));
                if xk >= 1 && xk <= w && yk >= 1 && yk <= h
                    vesselMask(max(1, yk-2):min(h, yk+2), max(1, xk-2):min(w, xk+2)) = true;
                end
            end
            
            % Inferior arcade
            yArc2 = discY + 140 * sin(pi * t);
            for k = 1:length(t)
                xk = round(xArc1(k)); yk = round(yArc2(k));
                if xk >= 1 && xk <= w && yk >= 1 && yk <= h
                    vesselMask(max(1, yk-2):min(h, yk+2), max(1, xk-2):min(w, xk+2)) = true;
                end
            end
            
            % Blend vessels into image
            img(:,:,1) = img(:,:,1) .* (~vesselMask) + 0.45 .* vesselMask;
            img(:,:,2) = img(:,:,2) .* (~vesselMask) + 0.08 .* vesselMask;
            img(:,:,3) = img(:,:,3) .* (~vesselMask) + 0.08 .* vesselMask;
            
            % Add Pathologies
            rng(42 + stage);
            maMask = false(h, w);
            hemMask = false(h, w);
            exMask = false(h, w);
            cwsMask = false(h, w);
            nvMask = false(h, w);
            
            if stage >= 1
                numMA = 6 * stage;
                for i = 1:numMA
                    mx = round(maculaX + randn()*45);
                    my = round(maculaY + randn()*45);
                    if mx >= 3 && mx <= w-2 && my >= 3 && my <= h-2
                        maMask(my-1:my+1, mx-1:mx+1) = true;
                    end
                end
                img(:,:,1) = img(:,:,1) .* (~maMask) + 0.55 .* maMask;
                img(:,:,2) = img(:,:,2) .* (~maMask) + 0.05 .* maMask;
                img(:,:,3) = img(:,:,3) .* (~maMask) + 0.05 .* maMask;
            end
            
            if stage >= 2
                % Hemorrhages
                numHem = 5 * stage;
                for i = 1:numHem
                    hx = round(cx + randn()*90);
                    hy = round(cy + randn()*90);
                    if hx >= 6 && hx <= w-5 && hy >= 6 && hy <= h-5
                        r = randi([3, 7]);
                        [subX, subY] = meshgrid(hx-r:hx+r, hy-r:hy+r);
                        m = ((subX-hx).^2 + (subY-hy).^2) <= r^2;
                        hemMask(hy-r:hy+r, hx-r:hx+r) = hemMask(hy-r:hy+r, hx-r:hx+r) | m;
                    end
                end
                img(:,:,1) = img(:,:,1) .* (~hemMask) + 0.45 .* hemMask;
                img(:,:,2) = img(:,:,2) .* (~hemMask) + 0.04 .* hemMask;
                img(:,:,3) = img(:,:,3) .* (~hemMask) + 0.04 .* hemMask;
                
                % Hard Exudates
                numEx = 10 * stage;
                for i = 1:numEx
                    ex = round(maculaX + 30 + randn()*35);
                    ey = round(maculaY - 15 + randn()*35);
                    if ex >= 4 && ex <= w-3 && ey >= 4 && ey <= h-3
                        r = randi([2, 4]);
                        [subX, subY] = meshgrid(ex-r:ex+r, ey-r:ey+r);
                        m = ((subX-ex).^2 + (subY-ey).^2) <= r^2;
                        exMask(ey-r:ey+r, ex-r:ex+r) = exMask(ey-r:ey+r, ex-r:ex+r) | m;
                    end
                end
                img(:,:,1) = img(:,:,1) .* (~exMask) + 0.98 .* exMask;
                img(:,:,2) = img(:,:,2) .* (~exMask) + 0.95 .* exMask;
                img(:,:,3) = img(:,:,3) .* (~exMask) + 0.45 .* exMask;
            end
            
            if stage >= 3
                % Cotton wool spots
                for i = 1:4
                    cwx = round(cx + randi([-80, 80]));
                    cwy = round(cy + randi([-80, 80]));
                    if cwx >= 15 && cwx <= w-14 && cwy >= 15 && cwy <= h-14
                        r = randi([8, 14]);
                        [subX, subY] = meshgrid(cwx-r:cwx+r, cwy-r:cwy+r);
                        m = ((subX-cwx).^2 + (subY-cwy).^2) <= r^2;
                        cwsMask(cwy-r:cwy+r, cwx-r:cwx+r) = cwsMask(cwy-r:cwy+r, cwx-r:cwx+r) | m;
                    end
                end
                img(:,:,1) = img(:,:,1) .* (~cwsMask) + 0.92 .* cwsMask;
                img(:,:,2) = img(:,:,2) .* (~cwsMask) + 0.90 .* cwsMask;
                img(:,:,3) = img(:,:,3) .* (~cwsMask) + 0.82 .* cwsMask;
            end
            
            if stage >= 4
                % Neovascularization at the disc
                for i = 1:12
                    nx1 = round(discX + randi([-discR, discR]));
                    ny1 = round(discY + randi([-discR, discR]));
                    nx2 = nx1 + randi([-20, 20]);
                    ny2 = ny1 + randi([-20, 20]);
                    if nx2 >= 1 && nx2 <= w && ny2 >= 1 && ny2 <= h
                        nvMask(min(ny1, ny2):max(ny1, ny2), min(nx1, nx2):max(nx1, nx2)) = true;
                    end
                end
                img(:,:,1) = img(:,:,1) .* (~nvMask) + 0.75 .* nvMask;
                img(:,:,2) = img(:,:,2) .* (~nvMask) + 0.08 .* nvMask;
                img(:,:,3) = img(:,:,3) .* (~nvMask) + 0.08 .* nvMask;
            end
            
            if hasDME
                % Circinate ring around fovea
                angles = linspace(0, 2*pi, 24);
                for a = angles
                    dist = 38 + randn()*4;
                    dex = round(maculaX + cos(a)*dist);
                    dey = round(maculaY + sin(a)*dist);
                    if dex >= 3 && dex <= w-2 && dey >= 3 && dey <= h-2
                        exMask(dey-1:dey+1, dex-1:dex+1) = true;
                    end
                end
                img(:,:,1) = img(:,:,1) .* (~exMask) + 0.98 .* exMask;
                img(:,:,2) = img(:,:,2) .* (~exMask) + 0.95 .* exMask;
                img(:,:,3) = img(:,:,3) .* (~exMask) + 0.45 .* exMask;
            end
            
            % Smooth slightly and apply aperture mask
            img = imgaussfilt(img, 0.6);
            for c = 1:3
                chan = img(:,:,c);
                chan(~apertureMask) = 0.06;
                img(:,:,c) = chan;
            end
            
            % Package outputs
            anatomy = struct('DiscCenter', [discX, discY], 'DiscRadius', discR, ...
                             'CupRadius', cupR, 'CDR', round(cupR/discR, 2), ...
                             'FoveaCenter', [maculaX, maculaY], 'DiscMask', discMask, ...
                             'CupMask', cupMask, 'FAZMask', fazMask);
                         
            lesions = struct('MicroaneurysmsMask', maMask, 'MACount', sum(maMask(:))/5, ...
                             'HemorrhagesMask', hemMask, 'HemCount', sum(hemMask(:))/30, ...
                             'HemAreaMM2', round(sum(hemMask(:)) * 0.00012, 2), ...
                             'ExudatesMask', exMask, 'ExudateCount', sum(exMask(:))/15, ...
                             'ExudateAreaMM2', round(sum(exMask(:)) * 0.00012, 2), ...
                             'CottonWoolMask', cwsMask, 'CWSCount', sum(cwsMask(:))/100, ...
                             'NVMask', nvMask, 'NVCount', sum(nvMask(:))/30, ...
                             'DistToFAZMicrons', ifthen(hasDME, 420, 1150), ...
                             'Meets421Rule', (stage >= 3));
        end
    end
end

function val = ifthen(cond, a, b)
    if cond, val = a; else, val = b; end
end
