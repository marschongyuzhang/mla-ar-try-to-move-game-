%% import the data from the subject in 8 class test and data collection
% hand open, hand closed, Wrist Flexion, Wrist Extension, Supination,
% Pronation, Rest
fs = 3000;
datasetFolder = "MyoelectricData";
if ~exist(datasetFolder,"dir")
unzip(localfile,datasetFolder)
end

sds1 = signalDatastore(datasetFolder,IncludeSubFolders=true,SampleRate=fs);
p = endsWith(sds1.Files,"d.mat"); %data 
sdssig = subset(sds1,p);

sds2 = signalDatastore(datasetFolder,SignalVariableNames=["motion";"data_indx"],IncludeSubfolders=true);
p = endsWith(sds2.Files,"i.mat"); %label
sdslbl = subset(sds2,p);
%% plot the data and label
signal = preview(sdssig);

for i = 1:8
    ax(i) = subplot(4,2,i);
    plot(signal(:,i))
    title("Channel"+i)
end

linkaxes(ax,"y")
%% ROI of the motion of the different motion

lbls = {};

i = 1;
while hasdata(sdslbl)

    label = read(sdslbl);
    
    idx_start = label{2}(2:end-1)';
    idx_end = [idx_start(2:end)-1;idx_start(end)+(3*fs)];
    
    val = categorical(label{1}(2:end-1)',[1 2 3 4 5 6 7], ... %this is the sequence of motion
          ["HandOpen" "HandClose" "WristFlexion" "WristExtension" "Supination" "Pronation" "Rest"]);
    ROI = [idx_start idx_end];

    if numel(val) < size(ROI,1)
        ROI(end,:) = [];
    elseif numel(val) > size(ROI,1)
        val(end) = [];
    end

    lbltable = table(ROI,val);
    lbls{i} = {lbltable};

    i = i+1;
end

%% show my data with label within my ROI
lblDS = signalDatastore(lbls);
lblstable = preview(lblDS);
lblstable{1}

%% create the connection between signal with label
DS = combine(sdssig,lblDS);
combinedData = preview(DS);

%% show the motion within the duration
figure
msk = signalMask(combinedData{2});
plotsigroi(msk,combinedData{1}(:,1))

%% preprocessing 
addpath('preprocessing.m');
tDS = transform(DS,@preprocessing);
transformedData = preview(tDS)

%% preprocessing before training 

rng default
%[trainIdx,~,testIdx] = dividerand(30,0.75,0,0.25);
[trainIdx,~,testIdx] = dividerand(30,0.8,0,0.2);

trainIdx_all = {};
m = 1;

for k = trainIdx
    
    if k == 1
       start = k;
    else
       start = ((k-1)*24)+1;
    end
    l = start:k*24;
    trainIdx_all{m} = l;
    m = m+1;
end

trainIdx_all = cell2mat(trainIdx_all)';
trainDS = subset(tDS,trainIdx_all);

testIdx_all = {};
m = 1;

for k = testIdx
    if k == 1
       start = k;
    else
       start = ((k-1)*24)+1;
    end
    l = start:k*24;
    testIdx_all{m} = l;
    m = m+1;
end

testIdx_all = cell2mat(testIdx_all)';
testDS = subset(tDS,testIdx_all);

%% LSTM network 
layers = [sequenceInputLayer(8),lstmLayer(80,OutputMode="sequence"),fullyConnectedLayer(4),softmaxLayer,classificationLayer];
% adam and shuffle
options = trainingOptions("adam", ...
    MaxEpochs=100, ...
    MiniBatchSize=32, ...
    Plots="training-progress",...
    InitialLearnRate=0.001,...
    Verbose=0,...
    Shuffle="every-epoch",...
    GradientThreshold=1e5,...
    DispatchInBackground=true);

%% train my model
traindata = readall(trainDS,"UseParallel",true);
rawNet = trainNetwork(traindata(:,1),traindata(:,2),layers,options);
%% evaluate 
testdata = readall(testDS);
predTest = classify(rawNet,testdata(:,1),MiniBatchSize=32);
confusionchart([testdata{:,2}],[predTest{:}],Normalization="column-normalized")