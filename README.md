## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

    helm repo add aks-store-demo https://azure-samples.github.io/aks-store-demo

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
{alias}` to see the charts.

To install the aks-store-demo chart:

    helm install petstore aks-store-demo/aks-store-demo-chart

To uninstall the chart:

    helm delete petstore

