close all
clear all
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
D=zeros(513,1);
for i=1:40
    %-------------------------------------------------
    if i==7
        M.MD(1,i,1);
    end
    if i==8
        M.MD(1,i,1);
    end
    if i==9
        M.MD(1,i,1);
    end
    if i==11
        M.MD(1,i,1);
    end
    if i==16
        M.MD(1,i,1);
    end
    if i==20
        M.MD(1,i,1);
    end
    %-------------------------------------------------
end
%%
M.SF1.V(:,3)=M.SF1.V(:,3)+M.SF1.D;
trisurf(M.SF1.T,M.SF1.V(:,1),M.SF1.V(:,2),M.SF1.V(:,3),M.SF1.D);
axis equal