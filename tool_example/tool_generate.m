%% Skin Model Generation Process
close all
clear all
clc

%% 1 Creat instance
tool=SkinModel;

%% 2 Read STL model
tool.Read('tool_hm_3b.stl');
tool.ShowOrg;

%% 3 Segment model into N surfaces
tool.Seg(50,53);
tool.ShowSeg;

%% 4 Get the Deviation Table 'DivTable' for simulation
tool.GetDivTable;

%% 5 Edit parameters in 'DivTable'
load Table
tool.DivTable=Table;

%% 6 Simulate for each surfaces
tool.DivSim;

%% 7 Solving the Combination by FEA with Penalty Function Approach
tool.Comb(15);
tool.ShowSM;

%% 8 Use 'ResetD' to set deviation to zero, not delet the model and generate new one
tool.ResetD;

%% 9 After generated skin model shape, export it to a FeatureGroup in GeoSpelling
tool.Export('ASM_1_F');

%% Save M, to use in next time

% save M M

%% Reload the model used before
% This is because each time the numbering of segmentation result is
% changing. To specify the surface I already konw, a model is saved in
% advance and reload here.
% Also, after Comb, the stiffness matrix K is already calculated. Reload
% will save time for calculation

% load M;

%% Simulate deviations for each surfaces
% It is possible to specify deviation for certain feature manually
% For more infomation, looking at the code

% M.RO(6,[3,3,0]);
% M.TR(3,[0,3,3]);
% M.MD(2,5,3);


