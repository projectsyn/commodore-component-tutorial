local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.fortune;

local namespace = 'syn-fortune';
local appName = 'fortune-app';
local portName = 'fortune-port';
local containerName = 'vshn/fortune-cookie-service:latest';
local labelSelector = {
  app: appName,
};

{
  namespace: kube.Namespace(namespace) {
    metadata: {
      name: namespace,
      labels: {
        name: namespace
      },
    },
  },

  service: kube.Service('fortune-service') {
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

  deployment: kube.Deployment('fortune-deployment') {
    metadata: {
      name: 'fortune-deployment',
      labels: labelSelector,
      namespace: namespace
    },
    spec: {
      replicas: 2,
      template: {
        spec: {
          containers: [
            {
              image: containerName,
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
