% data directory
cd('/data/');
languages = dir("onset_*");

% all languages
for lang = 1 : 21

    % read chunks
    cd('/data/');
    dat = readtable(languages(lang).name);
    langForSave = regexp(languages(lang).name,'\_[a-z]{2}\_','match');

    % extract
    nSent = max(dat.sent_idx);
    allSent = [];
    selDat = table2array(dat(:,[4 6 7]));
    selDat(:,4:5) = zeros(size(selDat,1),2);
    for s = 0 : nSent
        idx = selDat(:,1)==s;
        n = sum(idx);
        chnkId = 1:n;
        selDat(idx,4) = chnkId;
        disp([num2str(lang) '/' num2str(s)]);
    end
    selDat(:,5) = repmat(lang,size(selDat,1),1);

    % store
    allLangs{lang} = selDat;
end 

% save for R
cd('/data/');
data = cat(1,allLangs{:});
save('chunkDurationsIndices.mat','data')