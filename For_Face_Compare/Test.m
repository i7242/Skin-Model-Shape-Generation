close all
clear
clc
%%
M=SkinModel;
M.Read('fc_binary.stl');
%%
M.addprop('SF1');
M.SF1.V=M.V;
M.SF1.V(:,4)=linspace(1,size(M.SF1.V,1),size(M.SF1.V,1));
M.SF1.VN=M.VN;
M.SF1.VN(:,4)=linspace(1,size(M.SF1.V,1),size(M.SF1.V,1));
M.SF1.T=M.T;
M.SF1.N=M.N;
%%
M.MD(1,29,1);
%%
for i=1:20
    M.MD(1,i,1);
end
