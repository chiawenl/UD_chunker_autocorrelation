% data directory
cd('/data/');
languages = dir("onset_*");

% all languages
for lang = 1 : length(languages)

    % read chunks
    cd('/data/');
    dat = readtable(languages(lang).name);
    langForSave = regexp(languages(lang).name,'\_[a-z]{2}\_','match');

    % get onsets
    dat.sent_idx = dat.sent_idx + 1;
    dat.duration = round(dat.duration * 1000);
    C = unique(dat.sent_idx);

    % generate random sequences at 100 Hz
    clear allSeq nChnk;
    c = 1;
    for s = 1 : length(C)
        tscd = (dat(dat.sent_idx==C(s),:).duration)';
        nChnk = length(tscd);
        if nChnk > 1
            tscd = [1 round(cumsum(tscd)/10)];
            binSeq = zeros(1,max(tscd));
            binSeq(tscd) = 1;
            allSeq{c}(1,:) = binSeq;
            c = c + 1;
            display(num2str(s));
        end
    end

    % autocorrelation
    cd('/data/');
    clear allGoodLags;

    % all sentences
    for i = 1 : length(allSeq)

        % get sentence
        thisSeq = allSeq{i};
        chnkIdx = find(thisSeq(1,:));
        nChnk = length(chnkIdx);
        clear goodLags;

        % all counts
        for c_size = 2 : length(chnkIdx)

            % all subsequences
            for startChunk = 1 : nChnk - c_size

                % get sequence + permutations
                X = allSeq{i}(:,chnkIdx(startChunk) : chnkIdx(startChunk+c_size));
                X = X(2:end);
                [~,A] = sort(rand([1000 size(X,2)])');
                X(2:1001,:) = X(A)';
                X = [ones(size(X,1),1) X];
                for run = 1 : size(X,1)
                    nz = find(X(run,:));
                    maxLag(run) = nz(3)-1;
                end
                X = X - mean(X,2);
 
                % compute autocorrelation using FFT (fastest approach)
                N = size(X,2);
                L = 2*N - 1;
                X_fft = fft(X, L, 2);
                ACF_full = ifft(abs(X_fft).^2, [], 2);

                % Rearrange the result so that the lags run from -N+1 to N-1
                ACF_full = fftshift(ACF_full, 2);
                ACF_full = real(ACF_full);
                lags_full = -N+1 : N-1;

                % normalize
                normFactor = N - abs(lags_full);
                ACF_norm = ACF_full ./ normFactor;

                % truncate
                for run = 1 : size(ACF_norm,1)
                    badIndices = (lags_full <= 1) | (lags_full >= maxLag(run));
                    ACF_norm(run,badIndices) = NaN;
                end
                allAcf = ACF_norm(:,any(~isnan(ACF_norm),1));
                allAcf(allAcf<0) = 0;

                % get baseline
                obsLag = allAcf(1,:);
                rndLags = allAcf(2:end,:);

                % get cutoff
                cutOff = nan(1,size(rndLags,2));
                for lag = 1 : size(rndLags,2)
                    notNaN = rndLags(~isnan(rndLags(:,lag)),lag);
                    srtLags = sort(notNaN);
                    cutOff(lag) = srtLags(round(length(srtLags)/100*95),:);
                end
                isSig = obsLag>cutOff;
                if sum(isSig)>0
                    goodLags{c_size-1,startChunk} = find(isSig);
                end
                disp([num2str(lang) ' ' num2str(i) ' ' num2str(c_size)]);
            end
        end
        if exist("goodLags",'var')
            allGoodLags{i} = goodLags;
        end
    end

    % save
    save(['chunk_acf' langForSave{1} '.mat'],'allGoodLags','-v7.3');
end
