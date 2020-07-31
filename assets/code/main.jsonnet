local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.fortune;

local namespace = 'syn-fortune'; // <1>
local appName = 'fortune-app';
local portName = 'fortune-port';
local containerName = 'vshn/fortune-cookie-service:1.0';
local labelSelector = {
  app: appName,
};

{
  namespace: kube.Namespace('syn-fortune') {  // <2>
    metadata: {
      name: namespace,
      labels: {
        name: namespace
      },
    },
  },

  service: kube.Service('fortune-service') {  // <3>
    metadata: {
      name: 'fortune-service',
      labels: labelSelector,
      namespace: namespace
    },
    spec: {
      ports: [
        {
          port: 3000,
          targetPort: portName,
        },
      ],
      selector: labelSelector,
      type: 'LoadBalancer',
    },
  },

  deployment: kube.Deployment('fortune-deployment') {  // <4>
    metadata: {
      name: 'fortune-deployment',
      labels: labelSelector,
      namespace: namespace
    },
    spec: {
      template: {
        spec: {
          containers: [
            {
              image: containerName, // <5>
              name: 'fortune-container',
              ports: [
                {
                  containerPort: 9090,
                  name: portName,
                },
              ],
            },
          ],
        },
        metadata: {
          labels: labelSelector,
        },
      },
      selector: {
        matchLabels: labelSelector,
      },
      strategy: {
        type: 'Recreate',
      },
    },
  },
}
