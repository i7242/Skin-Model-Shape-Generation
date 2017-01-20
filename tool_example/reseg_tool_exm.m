figure
for i=1:53
    tool.ShowSeg(i);
end

%%
% 2
% 
% 22 to 5
% 
% 8-52-53
%%
tool.UnionSeg(8,53);
tool.UnionSeg(8,52);

tool.N_Surf=51;

tool.ReSeg(5,3,3);
tool.ReSeg(22,5,5);


%%
tool.addprop('SF20');
tool.SF20=tool.SF63;
delete( tool.DP(63));
tool.addprop('SF29');
tool.SF29=tool.SF62;
delete( tool.DP(62));
tool.addprop('SF39');
tool.SF39=tool.SF61;
delete( tool.DP(61));
tool.addprop('SF50');
tool.SF50=tool.SF60;
delete( tool.DP(60));
tool.addprop('SF55');
tool.SF55=tool.SF59;
delete( tool.DP(59));
tool.addprop('SF56');
tool.SF56=tool.SF58;
delete( tool.DP(58));
tool.N_Surf=57;
save tool_exm_5 tool

%%
for i=1:tool.N_Surf
    name=['SF',num2str(i)];
    tool.(name).N=tool.N(tool.(name).F,:);
    tool.(name).VN=zeros(size(tool.(name).V,1),4);
    for j=1:size(tool.(name).V,1)
        [r,~]=find(tool.(name).T(:,1:3)==tool.(name).V(j,4));
        N_used=tool.(name).N(r,1:3);
        VN_sum=[sum(N_used(:,1)),sum(N_used(:,2)),sum(N_used(:,3))];
        VN=VN_sum/norm(VN_sum);
        tool.(name).VN(j,:)=[VN,tool.(name).V(j,4)];
    end
    % 'D' is for the deviation of each vertices
    tool.(name).D=zeros(size(tool.(name).V,1),1);
end
%%
for i=1:tool.N_Surf
    tool.MD(i,randi(5,1),0.1);
    tool.MD(i,randi(5,1),0.1);
    tool.MD(i,randi(5,1),0.1);
    tool.MD(i,randi(5,1),0.1);
end