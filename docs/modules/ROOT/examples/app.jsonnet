local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.fortune;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('fortune', params.namespace, secrets=false);

{
  'fortune': app,
}