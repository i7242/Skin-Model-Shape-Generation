%% Skin Model Generation Process
close all
clear
clc

%% 1 Creat instance
M=SkinModel;

%% 2 Read STL model
M.Read('nominal_binary.stl');
M.ShowORG;

%% 3 Segment model into N surfaces
M.Seg(8,8);
M.ShowSEG;

%% *3 or reload the model after segmentation
% This is because each time the numbering of segmentation result is
% changing. To specify the surface I already konw, a model is saved in
% advance and reload here.
load M;

%% 4 Simulate deviations for each surfaces
M.RO(6,[3,3,0]);
M.TR(3,[0,3,3]);
M.MD(2,5,3);
M.MD(4,6,3);
M.MD(8,5,5);

%% 5 Solving the Combination by FEA with Penalty Function Approach

M.Comb(1);
M.ShowSM;

%% Use 'ResetD' to set deviation to zero, not delet the model and generate new one
M.ResetD;
